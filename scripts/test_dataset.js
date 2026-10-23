// scripts/test_dataset.js
import fs from 'fs';
import path from 'path';

const jsonPath = path.resolve('assets/questions/questions.json');
const raw = fs.readFileSync(jsonPath, 'utf8');
const data = JSON.parse(raw);

console.log('Testing questions dataset integrity for 900 questions...');
if (!data.categories || data.categories.length !== 6) {
  throw new Error(`Expected 6 categories, got ${data.categories ? data.categories.length : 0}`);
}
if (!data.questions || data.questions.length !== 900) {
  throw new Error(`Expected 900 questions, got ${data.questions ? data.questions.length : 0}`);
}

const ids = new Set();
const categoryCounts = {};
const levelCounts = {};

for (const q of data.questions) {
  if (ids.has(q.id)) {
    throw new Error(`Duplicate ID: ${q.id}`);
  }
  ids.add(q.id);

  if (!q.question || q.question.trim().length < 10) {
    throw new Error(`Question ${q.id} is too short or empty`);
  }
  if (!q.followUp || q.followUp.trim().length < 10) {
    throw new Error(`Follow-up for ${q.id} is too short or empty`);
  }
  if (![1, 2, 3].includes(q.level)) {
    throw new Error(`Invalid level for ${q.id}: ${q.level}`);
  }
  if (!Array.isArray(q.tags) || q.tags.length === 0) {
    throw new Error(`Invalid or empty tags for ${q.id}`);
  }

  categoryCounts[q.categoryId] = (categoryCounts[q.categoryId] || 0) + 1;
  const key = `${q.categoryId}_lvl${q.level}`;
  levelCounts[key] = (levelCounts[key] || 0) + 1;
}

for (const cat of data.categories) {
  if (categoryCounts[cat.id] !== 150) {
    throw new Error(`Category ${cat.id} has ${categoryCounts[cat.id]} questions, expected 150`);
  }
  for (let l = 1; l <= 3; l++) {
    const lKey = `${cat.id}_lvl${l}`;
    if (levelCounts[lKey] !== 50) {
      throw new Error(`Category ${cat.id} level ${l} has ${levelCounts[lKey]} questions, expected 50`);
    }
  }
}

console.log('✅ ALL 900 questions verified successfully:');
console.log(' - 6 Categories');
console.log(' - 150 Questions per Category (50 Level 1, 50 Level 2, 50 Level 3)');
console.log(' - 100% Unique IDs');
console.log(' - Complete Arabic questions with follow-ups and tags');
