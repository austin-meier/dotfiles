'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');

const PREFIX = 'claude-writing-code.';
const SUFFIX = '.flag';

const sessionKey = (sessionId) => String(sessionId || 'nosession').replace(/[^A-Za-z0-9._-]/g, '');

const markerStem = (sessionId) => PREFIX + sessionKey(sessionId) + '.';

const markerPath = (sessionId, language, dir = os.tmpdir()) =>
  path.join(dir, markerStem(sessionId) + language + SUFFIX);

const tryUnlink = (file) => {
  try { fs.unlinkSync(file); return true; } catch (_) { return false; }
};

const listMarkers = (sessionId, dir = os.tmpdir()) => {
  const stem = markerStem(sessionId);
  let names = [];
  try { names = fs.readdirSync(dir); } catch (_) { return []; }
  return names.filter((name) => name.startsWith(stem) && name.endsWith(SUFFIX));
};

const clearMarkers = (sessionId, dir = os.tmpdir()) =>
  listMarkers(sessionId, dir).filter((name) => tryUnlink(path.join(dir, name)));

module.exports = { sessionKey, markerPath, listMarkers, clearMarkers };
