'use strict';

const { test, before, after } = require('node:test');
const assert = require('node:assert');
const { createApp } = require('../src/index');

let server;
let baseUrl;

before(async () => {
  server = createApp().listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  const { port } = server.address();
  baseUrl = `http://127.0.0.1:${port}`;
});

after(() => {
  if (server) server.close();
});

test('GET /healthz returns 200 and status ok', async () => {
  const res = await fetch(`${baseUrl}/healthz`);
  assert.strictEqual(res.status, 200);
  const body = await res.json();
  assert.strictEqual(body.status, 'ok');
  assert.strictEqual(typeof body.uptime, 'number');
});

test('GET / returns the greeting payload and degrades gracefully without a DB', async () => {
  const res = await fetch(`${baseUrl}/`);
  assert.strictEqual(res.status, 200);
  const body = await res.json();
  assert.match(body.message, /Raintech DevOps Engineer/);
  // No SQL_SERVER/SQL_DATABASE in the test env -> endpoint still 200, DB flagged down.
  assert.strictEqual(typeof body.database, 'object');
  assert.strictEqual(body.database.connected, false);
});
