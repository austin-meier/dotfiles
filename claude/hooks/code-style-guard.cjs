'use strict';
/*
 * PreToolUse guard: enforces consulting the `writing-code` skill before writing code.
 *
 * Wired in settings.json as:
 *   node -e "require(require('os').homedir()+'/.config/claude/hooks/code-style-guard.cjs')"
 * (path resolved inside Node via os.homedir() so it needs no shell var / symlink / ~ and
 *  works identically under sh, Git Bash, and PowerShell.)
 *
 * Behavior: on the FIRST Write/Edit/MultiEdit to a tracked code language per (session, language),
 * exit 2 to block the call and print the reminder to stderr (the one channel PreToolUse reliably
 * feeds back to the model). Subsequent edits of that language in the same session pass through.
 */
const fs = require('fs');
const os = require('os');
const path = require('path');

let raw = '';
try { raw = fs.readFileSync(0, 'utf8'); } catch (_) { /* no stdin */ }
if (raw.charCodeAt(0) === 0xFEFF) raw = raw.slice(1); // strip BOM (e.g. PowerShell pipe)

let data;
try { data = JSON.parse(raw || '{}'); } catch (_) { process.exit(0); }

const tool = data.tool_name || '';
if (tool !== 'Write' && tool !== 'Edit' && tool !== 'MultiEdit') process.exit(0);

const file = (data.tool_input && data.tool_input.file_path) || '';
const ext = path.extname(file).toLowerCase().slice(1);

/* Tracked programming languages only — config/markup/shell are intentionally excluded so
 * editing dotfiles (lua, el, sh, ps1, json, md, ...) never triggers the guard. */
const LANG = {
  ts: 'typescript', tsx: 'typescript', mts: 'typescript', cts: 'typescript',
  js: 'typescript', jsx: 'typescript', mjs: 'typescript', cjs: 'typescript',
  clj: 'clojure', cljs: 'clojure', cljc: 'clojure', edn: 'clojure',
  rs: 'rust',
  c: 'c', h: 'c', cpp: 'c', cc: 'c', cxx: 'c', hpp: 'c', hh: 'c',
  java: 'java', py: 'python', go: 'go', ex: 'elixir', exs: 'elixir', cs: 'csharp',
};
const lang = LANG[ext];
if (!lang) process.exit(0);

/* Once per (session, language) gate via a marker file in the temp dir. */
const session = String(data.session_id || 'nosession').replace(/[^A-Za-z0-9._-]/g, '');
const marker = path.join(os.tmpdir(), 'claude-writing-code.' + session + '.' + lang + '.flag');

try {
  if (fs.existsSync(marker)) process.exit(0);
  fs.writeFileSync(marker, String(Date.now()));
} catch (_) { /* if tmp is unwritable, fall through and remind anyway */ }

const msg = [
  '[code-style-guard] STOP - consult the writing-code skill before writing ' + lang + ' code:',
  '  1. Read skills/writing-code/SKILL.md (cross-language principles).',
  '  2. Read skills/writing-code/languages/' + lang + '.md (if it exists).',
  '  3. If this project depends on @jambnc/common or @jam/schemas, also read the jam-plus skill.',
  'Then re-issue this ' + tool + '. (This guard fires once per language per session.)',
].join('\n');

process.stderr.write(msg + '\n');
process.exit(2);
