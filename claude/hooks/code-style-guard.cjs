'use strict';
const fs = require('fs');
const path = require('path');
const scan = require('./lib/comment-scan.cjs');
const prose = require('./lib/prose-scan.cjs');
const markers = require('./lib/style-markers.cjs');

let raw = '';
try { raw = fs.readFileSync(0, 'utf8'); } catch (_) { raw = ''; }
if (raw.charCodeAt(0) === 0xFEFF) raw = raw.slice(1);

let data;
try { data = JSON.parse(raw || '{}'); } catch (_) { process.exit(0); }

const tool = data.tool_name || '';
if (tool !== 'Write' && tool !== 'Edit' && tool !== 'MultiEdit') process.exit(0);

const file = (data.tool_input && data.tool_input.file_path) || '';
const ext = path.extname(file).toLowerCase().slice(1);

const lang = scan.LANGUAGES[ext] || (prose.isProse(file) ? 'prose' : undefined);
if (!lang) process.exit(0);

const marker = markers.markerPath(data.session_id, lang);

const alreadyReminded = () => {
  try {
    if (fs.existsSync(marker)) return true;
    fs.writeFileSync(marker, String(Date.now()));
  } catch (_) { return false; }
  return false;
};

if (alreadyReminded()) process.exit(0);

const codeReminder = () => [
  '[code-style-guard] STOP - load the writing-code skill before writing ' + lang + ' code:',
  '  1. Invoke it with the Skill tool: Skill(writing-code). Use the Skill tool, not Read, so it',
  '     survives context compaction.',
  '  2. Read ~/.claude/skills/writing-code/languages/' + lang + '.md if it exists.',
  '  3. If this project depends on @jambnc/common or @jam/schemas, also invoke Skill(jam-plus).',
  'Then re-issue this ' + tool + '. (Fires once per language per session, and again after compaction.)',
];

const proseReminder = () => [
  '[code-style-guard] STOP - load the writing-docs skill before writing prose:',
  '  1. Invoke it with the Skill tool: Skill(writing-docs). Use the Skill tool, not Read, so it',
  '     survives context compaction.',
  'Then re-issue this ' + tool + '. (Fires once per session, and again after compaction.)',
];

process.stderr.write((lang === 'prose' ? proseReminder() : codeReminder()).join('\n') + '\n');
process.exit(2);
