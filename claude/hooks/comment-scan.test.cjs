'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { languageOf, scanComments, writtenText, report } = require('./lib/comment-scan.cjs');

const texts = (source, language) => scanComments(source, language).map((finding) => finding.text);

test('languageOf maps tracked code extensions', () => {
   assert.equal(languageOf('/a/b/thing.ts'), 'typescript');
   assert.equal(languageOf('thing.CJS'), 'typescript');
   assert.equal(languageOf('mod.rs'), 'rust');
   assert.equal(languageOf('core.cljc'), 'clojure');
   assert.equal(languageOf('main.exs'), 'elixir');
});

test('languageOf ignores config, markup, shell and lua', () => {
   ['README.md', 'settings.json', 'init.lua', 'install.sh', 'config.el', 'wezterm.toml', '', undefined].forEach(
      (file) => assert.equal(languageOf(file), undefined)
   );
});

test('flags line and block comments', () => {
   assert.deepEqual(texts('const a = 1; // set a\n', 'typescript'), ['// set a']);
   assert.deepEqual(texts('/* multi\n   line */\nconst a = 1;\n', 'typescript'), ['/* multi\n   line */']);
   assert.deepEqual(texts('x = 1  # why\n', 'python'), ['# why']);
   assert.deepEqual(texts('(def a 1) ; why\n', 'clojure'), ['; why']);
   assert.deepEqual(texts('let a = 1; /// doc\n', 'rust'), ['/// doc']);
});

test('reports the line the comment starts on', () => {
   assert.deepEqual(scanComments('a\nb\n// here\n', 'typescript'), [{ line: 3, text: '// here' }]);
});

test('does not flag comment markers inside strings', () => {
   assert.deepEqual(texts('const url = "https://example.com/a";\n', 'typescript'), []);
   assert.deepEqual(texts("const s = 'a // b';\n", 'typescript'), []);
   assert.deepEqual(texts('const s = `a /* b */ c`;\n', 'typescript'), []);
   assert.deepEqual(texts('s = "a # b"\n', 'python'), []);
   assert.deepEqual(texts('s = """a # b"""\n', 'python'), []);
   assert.deepEqual(texts('(def s "a ; b")\n', 'clojure'), []);
   assert.deepEqual(texts('s := `raw // text`\n', 'go'), []);
});

test('regex literals do not desync the scanner', () => {
   assert.deepEqual(texts("const re = /a'b/;\n// after\n", 'typescript'), ['// after']);
   assert.deepEqual(texts('const re = /https:\\/\\//;\n', 'typescript'), []);
   assert.deepEqual(texts("const re = /[/'\"]/g;\n// after\n", 'typescript'), ['// after']);
   assert.deepEqual(texts("return /a'b/.test(x); // why\n", 'typescript'), ['// why']);
});

test('division is not mistaken for a regex literal', () => {
   assert.deepEqual(texts('const half = total / count; // halve it\n', 'typescript'), ['// halve it']);
   assert.deepEqual(texts('const r = a / b / c;\n', 'typescript'), []);
});

test('does not flag a bare url fragment outside a string', () => {
   assert.deepEqual(texts('https://example.com/path\n', 'typescript'), []);
});

test('a rust lifetime does not swallow the rest of the file', () => {
   assert.deepEqual(texts("fn f<'a>(x: &'a str) {}\n// gotcha\n", 'rust'), ['// gotcha']);
});

test('char literals do not open a string', () => {
   assert.deepEqual(texts("char q = '\"'; // still a comment\n", 'c'), ['// still a comment']);
   assert.deepEqual(texts('(def c \\" ) ; still a comment\n', 'clojure'), ['; still a comment']);
});

test('escaped quotes do not end a string early', () => {
   assert.deepEqual(texts('const s = "a \\" // b";\n', 'typescript'), []);
});

test('allows tool directives, shebangs and generated-file banners', () => {
   assert.deepEqual(texts('// eslint-disable-next-line no-console\n', 'typescript'), []);
   assert.deepEqual(texts('// @ts-expect-error upstream types are wrong\n', 'typescript'), []);
   assert.deepEqual(texts('/// <reference types="node" />\n', 'typescript'), []);
   assert.deepEqual(texts('#!/usr/bin/env python3\n', 'python'), []);
   assert.deepEqual(texts('x = 1  # noqa: E501\n', 'python'), []);
   assert.deepEqual(texts('//go:embed static\n', 'go'), []);
});

test('an unterminated block comment is still flagged', () => {
   assert.deepEqual(texts('/* forgot to close\n', 'typescript'), ['/* forgot to close']);
});

test('writtenText pulls only the newly written text', () => {
   assert.equal(writtenText('Write', { content: 'a' }), 'a');
   assert.equal(writtenText('Edit', { old_string: '// kept', new_string: 'b' }), 'b');
   assert.equal(writtenText('MultiEdit', { edits: [{ new_string: 'a' }, { new_string: 'b' }] }), 'a\nb');
   assert.equal(writtenText('Read', { content: '// x' }), '');
   assert.equal(writtenText('MultiEdit', {}), '');
});

test('an unknown language scans clean', () => {
   assert.deepEqual(scanComments('// x', undefined), []);
   assert.deepEqual(scanComments(undefined, 'typescript'), []);
});

test('report lists findings, truncates long ones and caps the list', () => {
   const many = Array.from({ length: 12 }, (_, at) => ({ line: at, text: '// c' + at }));
   const output = report(many);
   assert.match(output, /landed with 12 comments/);
   assert.match(output, /and 2 more/);
   assert.match(report([{ line: 1, text: '// ' + 'x'.repeat(200) }]), /\.\.\./);
   assert.match(report([{ line: 1, text: '// x' }]), /landed with 1 comment /);
});
