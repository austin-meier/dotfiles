'use strict';
const fs = require('fs');
const markers = require('./lib/style-markers.cjs');

let raw = '';
try { raw = fs.readFileSync(0, 'utf8'); } catch (_) { raw = ''; }
if (raw.charCodeAt(0) === 0xFEFF) raw = raw.slice(1);

let data;
try { data = JSON.parse(raw || '{}'); } catch (_) { process.exit(0); }

markers.clearMarkers(data.session_id);
process.exit(0);
