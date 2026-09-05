'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { sessionKey, markerPath, listMarkers, clearMarkers } = require('./lib/style-markers.cjs');

const tempDir = () => fs.mkdtempSync(path.join(os.tmpdir(), 'style-markers-'));

test('sessionKey strips anything unsafe for a filename', () => {
   assert.equal(sessionKey('abc-123_x.y'), 'abc-123_x.y');
   assert.equal(sessionKey('a/b\\c d'), 'abcd');
   assert.equal(sessionKey(undefined), 'nosession');
});

test('markerPath lives in the given dir and encodes session and language', () => {
   assert.equal(markerPath('s1', 'rust', '/x'), path.join('/x', 'claude-writing-code.s1.rust.flag'));
});

test('clearMarkers removes only the markers for that session', () => {
   const dir = tempDir();
   ['s1:typescript', 's1:rust', 's2:typescript'].forEach((pair) => {
      const [session, language] = pair.split(':');
      fs.writeFileSync(markerPath(session, language, dir), '1');
   });
   fs.writeFileSync(path.join(dir, 'unrelated.flag'), '1');

   const removed = clearMarkers('s1', dir).sort();

   assert.deepEqual(removed, ['claude-writing-code.s1.rust.flag', 'claude-writing-code.s1.typescript.flag']);
   assert.deepEqual(listMarkers('s1', dir), []);
   assert.deepEqual(listMarkers('s2', dir), ['claude-writing-code.s2.typescript.flag']);
   assert.ok(fs.existsSync(path.join(dir, 'unrelated.flag')));
   fs.rmSync(dir, { recursive: true });
});

test('clearMarkers on a missing dir returns nothing', () => {
   assert.deepEqual(clearMarkers('s1', path.join(os.tmpdir(), 'does-not-exist-' + Date.now())), []);
});
