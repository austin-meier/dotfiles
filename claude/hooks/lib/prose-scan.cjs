'use strict';

const path = require('path');

const PROSE = new Set(['md', 'mdx', 'markdown', 'txt', 'org', 'rst']);
const EM_DASH = '\u2014';

const isProse = (file) => PROSE.has(path.extname(String(file || '')).toLowerCase().slice(1));

const scanEmDashes = (text) => {
  const source = typeof text === 'string' ? text : '';
  if (source.length === 0) return [];
  return source
    .split('\n')
    .map((line, index) => ({ line: index + 1, text: line.trim() }))
    .filter((entry) => entry.text.includes(EM_DASH));
};

const report = (findings) => {
  const shown = findings.slice(0, 10);
  const overflow = findings.length - shown.length;
  const oneLine = (finding) => {
    const flat = finding.text.replace(/\s+/g, ' ');
    return '  - line ' + finding.line + ': ' + (flat.length > 100 ? flat.slice(0, 97) + '...' : flat);
  };

  return [
    '[prose-guard] That edit landed with ' + findings.length + ' em dash' + (findings.length === 1 ? '' : 'es') + ' in it.',
    'The writing-docs skill is explicit: no em dashes, ever. Use a comma, parentheses, a period, or restructure.',
    '',
    ...shown.map(oneLine),
    ...(overflow > 0 ? ['  ...and ' + overflow + ' more'] : []),
    '',
    'Re-issue the edit without them.',
  ].join('\n');
};

module.exports = { isProse, scanEmDashes, report, PROSE, EM_DASH };
