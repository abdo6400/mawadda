// scripts/bundle_flutter_project.js
import fs from 'fs';
import path from 'path';
import JSZip from 'jszip';

const zip = new JSZip();

const filesToInclude = [
  'pubspec.yaml',
  'analysis_options.yaml',
  'README.md',
  'BUILD.md',
  'FEATURES.md',
  'CONTENT_GUIDELINES.md',
  '.github/workflows/android-apk.yml',
];

const dirsToInclude = [
  'lib',
  'assets',
  'android',
  'test'
];

function addFileToZip(filePath) {
  if (fs.existsSync(filePath)) {
    const content = fs.readFileSync(filePath);
    zip.file(filePath, content);
  }
}

function addDirToZip(dirPath) {
  if (!fs.existsSync(dirPath)) return;
  const entries = fs.readdirSync(dirPath, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dirPath, entry.name);
    if (entry.isDirectory()) {
      addDirToZip(fullPath);
    } else {
      const content = fs.readFileSync(fullPath);
      zip.file(fullPath, content);
    }
  }
}

// Add files
filesToInclude.forEach(f => addFileToZip(f));

// Add directories
dirsToInclude.forEach(d => addDirToZip(d));

const publicDir = path.resolve('public');
if (!fs.existsSync(publicDir)) {
  fs.mkdirSync(publicDir, { recursive: true });
}

zip.generateAsync({ type: 'nodebuffer', compression: 'DEFLATE' }).then((content) => {
  const outputPath = path.join(publicDir, 'mawadda_flutter_project.zip');
  fs.writeFileSync(outputPath, content);
  console.log(`Successfully generated ${outputPath} (${(content.length / 1024).toFixed(1)} KB)`);
});
