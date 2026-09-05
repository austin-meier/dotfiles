'use strict';
const fs = require('fs');
const scan = require('./lib/comment-scan.cjs');

let raw = '';
try { raw = fs.readFileSync(0, 'utf8'); } catch (_) { raw = ''; }
if (raw.charCodeAt(0) === 0xFEFF) raw = raw.slice(1);

let data;
try { data = JSON.parse(raw || '{}'); } catch (_) { process.exit(0); }

const input = data.tool_input || {};
const language = scan.languageOf(input.file_path);
if (!language) process.exit(0);

const findings = scan.scanComments(scan.writtenText(data.tool_name || '', input), language);
if (findings.length === 0) process.exit(0);

process.stderr.write(scan.report(findings) + '\n');
process.exit(2);
