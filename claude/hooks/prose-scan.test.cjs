'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { isProse, scanEmDashes, report } = require('./lib/prose-scan.cjs');

test('isProse matches markdown, text, org and rst', () => {
   ['README.md', 'a/b.MDX', 'notes.txt', 'config.org', 'index.rst', 'x.markdown'].forEach(
      (file) => assert.equal(isProse(file), true, file)
   );
});

test('isProse ignores code, config and nothing', () => {
   ['a.ts', 'settings.json', 'init.lua', 'x.sh', '', undefined].forEach(
      (file) => assert.equal(isProse(file), false, String(file))
   );
});

test('scanEmDashes reports each line holding one', () => {
   const text = 'clean line\nbad \u2014 line\nalso clean\nworse \u2014 twice \u2014 here\n';
   assert.deepEqual(scanEmDashes(text), [
      { line: 2, text: 'bad \u2014 line' },
      { line: 4, text: 'worse \u2014 twice \u2014 here' },
   ]);
});

test('scanEmDashes ignores hyphens, en dashes and table rules', () => {
   assert.deepEqual(scanEmDashes('a - b\nc \u2013 d\n|---|---|\n--flag\n'), []);
   assert.deepEqual(scanEmDashes(''), []);
   assert.deepEqual(scanEmDashes(undefined), []);
});

test('report names the guard, counts, and caps the list', () => {
   const one = report([{ line: 3, text: 'x \u2014 y' }]);
   assert.match(one, /^\[prose-guard\] That edit landed with 1 em dash in it\./);
   assert.match(one, /line 3: x \u2014 y/);

   const many = report(Array.from({ length: 12 }, (_, i) => ({ line: i + 1, text: 'z' })));
   assert.match(many, /12 em dashes/);
   assert.match(many, /\.\.\.and 2 more/);
});
