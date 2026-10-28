// scripts/test_2400_dataset.js
import fs from 'fs';
import path from 'path';

console.log('Testing 2,400 Questions Dataset Integrity...');

const rawData = fs.readFileSync('assets/questions/questions.json', 'utf8');
const data = JSON.parse(rawData);

const { categories, questions } = data;

// Both applications must display the same content for every saved question ID.
const webSource = fs.readFileSync('src/data/questionsData.ts', 'utf8');
const marker = 'export const MAWADDA_DATA: MawaddaData = ';
const start = webSource.indexOf(marker);
if (start < 0) throw new Error('Web question dataset not found');
const webData = JSON.parse(webSource.slice(start + marker.length).trim().replace(/;$/, ''));
if (JSON.stringify(webData) !== JSON.stringify(data)) {
  throw new Error('Flutter and web question datasets differ');
}

// 1. Categories check
if (!categories || categories.length !== 8) {
  throw new Error(`Expected exactly 8 categories, got ${categories ? categories.length : 0}`);
}

const expectedCategoryIds = [
  'religion_values',
  'personality_thinking',
  'family_relationships',
  'responsibilities_life',
  'finance_work',
  'children_future',
  'health_lifestyle',
  'intellect_interests'
];

for (const id of expectedCategoryIds) {
  if (!categories.find(c => c.id === id)) {
    throw new Error(`Missing expected category: ${id}`);
  }
}

// 2. Questions length check
if (!questions || questions.length !== 2400) {
  throw new Error(`Expected exactly 2400 questions, got ${questions ? questions.length : 0}`);
}

// 3. Unique IDs check
const idSet = new Set();
for (const q of questions) {
  if (idSet.has(q.id)) {
    throw new Error(`Duplicate question ID: ${q.id}`);
  }
  idSet.add(q.id);
}

// 4. Unique Question Texts check
const questionSet = new Set();
for (const q of questions) {
  if (questionSet.has(q.question)) {
    throw new Error(`Duplicate question text detected: "${q.question}"`);
  }
  questionSet.add(q.question);
}

// 5. Unique Follow-up Texts check
const followUpSet = new Set();
for (const q of questions) {
  if (followUpSet.has(q.followUp)) {
    throw new Error(`Duplicate follow-up text detected: "${q.followUp}"`);
  }
  followUpSet.add(q.followUp);
}

// 6. No index numbering check like (1), (2), (50)
const indexNumberRegex = /\(\d+\)/;
for (const q of questions) {
  if (indexNumberRegex.test(q.question)) {
    throw new Error(`Question contains index numbering like (1): "${q.question}"`);
  }
  if (indexNumberRegex.test(q.followUp)) {
    throw new Error(`Follow-up contains index numbering like (1): "${q.followUp}"`);
  }
}

// 7. Category distribution check: 300 per category (100 L1, 100 L2, 100 L3)
for (const cat of categories) {
  const catQuestions = questions.filter(q => q.categoryId === cat.id);
  if (catQuestions.length !== 300) {
    throw new Error(`Category ${cat.id} has ${catQuestions.length} questions, expected 300`);
  }

  const l1 = catQuestions.filter(q => q.level === 1);
  const l2 = catQuestions.filter(q => q.level === 2);
  const l3 = catQuestions.filter(q => q.level === 3);

  if (l1.length !== 100) throw new Error(`Category ${cat.id} L1 has ${l1.length}, expected 100`);
  if (l2.length !== 100) throw new Error(`Category ${cat.id} L2 has ${l2.length}, expected 100`);
  if (l3.length !== 100) throw new Error(`Category ${cat.id} L3 has ${l3.length}, expected 100`);
}

// 8. Quality & length check
for (const q of questions) {
  if (q.question.trim().length < 20) {
    throw new Error(`Question text too short (${q.question.length} chars): ${q.question}`);
  }
  if (q.followUp.trim().length < 20) {
    throw new Error(`Follow-up text too short (${q.followUp.length} chars): ${q.followUp}`);
  }
  if (!q.tags || q.tags.length === 0) {
    throw new Error(`Question has no tags: ${q.id}`);
  }
}

// Catch specific previously corrected phrases; this is not a semantic or
// scholarly review and must not be treated as proof of content compliance.
const correctedPhrases = [
  'علاقات سابقة',
  'علاقة حميمية',
  'ننام معاً',
  'بطانية واحدة',
  'داووا مرضاكم بالصدقة',
  'بروا آباءكم تبركم أبناؤكم',
];
for (const q of questions) {
  for (const phrase of correctedPhrases) {
    if (`${q.question} ${q.followUp}`.includes(phrase)) {
      throw new Error(`Previously corrected phrase in ${q.id}: ${phrase}`);
    }
  }
}

console.log('✅ ALL 2,400 questions verified with 100% data integrity:');
console.log(' - 8 Categories (Added: الصحة والعافية ونمط العيش، الفكر والثقافة والاهتمامات)');
console.log(' - Exactly 300 Questions per Category (100 Level 1, 100 Level 2, 100 Level 3)');
console.log(' - 100% Unique Question IDs (2,400 / 2,400)');
console.log(' - 100% Unique Question Texts (2,400 / 2,400 - ZERO DUPLICATES)');
console.log(' - 100% Unique Follow-up Texts (2,400 / 2,400 - ZERO DUPLICATES)');
console.log(' - ZERO index numbers like (1) or (${i}) in question texts');
console.log(' - Flutter and web datasets match');
