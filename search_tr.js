const fs = require('fs');
const path = require('path');
const brainDir = 'C:\\Users\\Erol kaan ÖZCAN\\.gemini\\antigravity\\brain';

function walk(dir) {
  let files = [];
  try {
    const list = fs.readdirSync(dir);
    for (const file of list) {
      const fullPath = path.join(dir, file);
      const stat = fs.statSync(fullPath);
      if (stat && stat.isDirectory()) {
        files = files.concat(walk(fullPath));
      } else if (file === 'transcript.jsonl' || file === 'transcript_full.jsonl') {
        files.push(fullPath);
      }
    }
  } catch (e) {}
  return files;
}

const allTranscripts = walk(brainDir);
for (const t of allTranscripts) {
  const content = fs.readFileSync(t, 'utf8');
  const lines = content.split('\n');
  lines.forEach((line, idx) => {
    if (line.includes('60 gr') || line.includes('433.080') || line.includes('bilezik') || line.includes('350.000')) {
      console.log(`${path.basename(path.dirname(path.dirname(t)))}/${path.basename(t)}:${idx + 1}: ${line.substring(0, 300)}`);
    }
  });
}
console.log('Search complete.');
