'use strict';

const path = require('path');

const LANGUAGES = {
  ts: 'typescript', tsx: 'typescript', mts: 'typescript', cts: 'typescript',
  js: 'typescript', jsx: 'typescript', mjs: 'typescript', cjs: 'typescript',
  clj: 'clojure', cljs: 'clojure', cljc: 'clojure', edn: 'clojure',
  rs: 'rust',
  c: 'c', h: 'c', cpp: 'c', cc: 'c', cxx: 'c', hpp: 'c', hh: 'c',
  java: 'java', py: 'python', go: 'go', ex: 'elixir', exs: 'elixir', cs: 'csharp',
};

const SYNTAX = {
  typescript: { line: ['//'], block: true, quotes: ['"', "'", '`'], regexLiteral: true },
  rust: { line: ['//'], block: true, quotes: ['"'], charLiteral: true },
  c: { line: ['//'], block: true, quotes: ['"'], charLiteral: true },
  java: { line: ['//'], block: true, quotes: ['"'], charLiteral: true },
  csharp: { line: ['//'], block: true, quotes: ['"'], charLiteral: true },
  go: { line: ['//'], block: true, quotes: ['"', '`'], charLiteral: true },
  python: { line: ['#'], block: false, quotes: ['"""', "'''", '"', "'"] },
  elixir: { line: ['#'], block: false, quotes: ['"""', '"'] },
  clojure: { line: [';'], block: false, quotes: ['"'], backslashChar: true },
};

const ALLOWED = [
  /^#!/,
  /^#\s*-\*-/,
  /^#\s*(noqa|type:|pragma:|pylint:|mypy:|ruff:|fmt:|coding[:=])/,
  /eslint-(disable|enable)/,
  /prettier-ignore/,
  /biome-ignore/,
  /@ts-(expect-error|ignore|nocheck)/,
  /^\/\/\/\s*<reference/,
  /(istanbul|c8|v8) ignore/,
  /SPDX-License-Identifier/,
  /^\/\/\s*go:/,
  /^\/\/\s*Code generated .* DO NOT EDIT/,
];

const REGEX_CONTEXT = new Set(['(', ',', '=', ':', '[', '!', '&', '|', '?', '{', '}', ';', '+', '-', '*', '%', '~', '^', '<', '>', undefined]);

const REGEX_KEYWORD = /\b(return|typeof|case|in|of|do|else|yield|await|delete|void|new|throw)\s*$/;

const regexLiteralEnd = (source, start) => {
  let at = start + 1;
  let inClass = false;
  while (at < source.length) {
    const char = source[at];
    if (char === '\n') return undefined;
    if (char === '\\') { at += 2; continue; }
    if (inClass) { if (char === ']') inClass = false; at += 1; continue; }
    if (char === '[') { inClass = true; at += 1; continue; }
    if (char === '/') {
      let end = at + 1;
      while (end < source.length && /[a-z]/.test(source[end])) end += 1;
      return end;
    }
    at += 1;
  }
  return undefined;
};

const CHAR_LITERAL = /^'(?:\\.|[^'\\])'/;

const EXTRACTORS = {
  Write: (input) => [input.content],
  Edit: (input) => [input.new_string],
  MultiEdit: (input) => (Array.isArray(input.edits) ? input.edits.map((edit) => edit.new_string) : []),
};

const languageOf = (file) => LANGUAGES[path.extname(String(file || '')).toLowerCase().slice(1)];

const isDirective = (body) => ALLOWED.some((pattern) => pattern.test(body.trim()));

const writtenText = (toolName, toolInput) => {
  const extract = EXTRACTORS[toolName];
  if (!extract) return '';
  return extract(toolInput || {})
    .filter((piece) => typeof piece === 'string')
    .join('\n');
};

const scanComments = (text, language) => {
  const syntax = SYNTAX[language];
  const source = typeof text === 'string' ? text : '';
  if (!syntax || source.length === 0) return [];

  const findings = [];
  let index = 0;
  let line = 1;
  let quote;
  let lastCode;

  const skipTo = (stop) => {
    for (let at = index; at < stop; at += 1) if (source[at] === '\n') line += 1;
    index = stop;
  };

  const record = (stop) => {
    const body = source.slice(index, stop);
    if (!isDirective(body)) findings.push({ line, text: body.trim() });
    skipTo(stop);
  };

  while (index < source.length) {
    if (quote !== undefined) {
      if (source[index] === '\\') skipTo(Math.min(index + 2, source.length));
      else if (source.startsWith(quote, index)) { index += quote.length; quote = undefined; }
      else skipTo(index + 1);
      continue;
    }

    const opener = syntax.quotes.find((candidate) => source.startsWith(candidate, index));
    if (opener !== undefined) { quote = opener; lastCode = opener; index += opener.length; continue; }

    if (syntax.regexLiteral && source[index] === '/' && source[index + 1] !== '/' && source[index + 1] !== '*'
        && (REGEX_CONTEXT.has(lastCode) || REGEX_KEYWORD.test(source.slice(Math.max(0, index - 12), index)))) {
      const end = regexLiteralEnd(source, index);
      if (end !== undefined) { lastCode = '/'; index = end; continue; }
    }

    const charLiteral = syntax.charLiteral && CHAR_LITERAL.exec(source.slice(index, index + 8));
    if (charLiteral) { index += charLiteral[0].length; continue; }
    if (syntax.backslashChar && source[index] === '\\') { skipTo(Math.min(index + 2, source.length)); continue; }

    const marker = syntax.line.find((candidate) => source.startsWith(candidate, index));
    if (marker === '//' && source[index - 1] === ':') { index += 2; continue; }
    if (marker !== undefined) {
      const newline = source.indexOf('\n', index);
      record(newline === -1 ? source.length : newline);
      continue;
    }

    if (syntax.block && source.startsWith('/*', index)) {
      const close = source.indexOf('*/', index + 2);
      record(close === -1 ? source.length : close + 2);
      continue;
    }

    if (!/\s/.test(source[index])) lastCode = source[index];
    skipTo(index + 1);
  }

  return findings;
};

const report = (findings) => {
  const shown = findings.slice(0, 10);
  const overflow = findings.length - shown.length;
  const oneLine = (finding) => {
    const flat = finding.text.replace(/\s+/g, ' ');
    return '  - ' + (flat.length > 100 ? flat.slice(0, 97) + '...' : flat);
  };

  return [
    '[comment-guard] That edit landed with ' + findings.length + ' comment' + (findings.length === 1 ? '' : 's') + ' in it.',
    'The writing-code skill is explicit: write ZERO comments. Not sparse ones. Zero.',
    '',
    ...shown.map(oneLine),
    ...(overflow > 0 ? ['  - ...and ' + overflow + ' more'] : []),
    '',
    'Edit the file again and delete every one of them. If a line felt like it needed the',
    'explanation, that is a signal to rename it or extract a named function until it does not.',
    'Comments that were already in the file are the user\'s. Leave those exactly as they are.',
    'If one of these documents a genuine trap (an upstream bug workaround, a non-obvious',
    'ordering dependency) that would cost a developer hours, still remove it from the file and',
    'say so in your reply instead, so the user can decide to write that comment themselves.',
  ].join('\n');
};

module.exports = { languageOf, scanComments, writtenText, report, LANGUAGES };
