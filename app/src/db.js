'use strict';

const sql = require('mssql');

// A single lazily-initialised connection pool is reused across requests.
// The app authenticates to Azure SQL with its App Service system-assigned
// managed identity (Entra ID) — there is NO password anywhere. SQL_SERVER and
// SQL_DATABASE are plain, non-secret app settings (see infra/ + docs/SECURITY.md).
let poolPromise = null;

function buildConfig() {
  const server = process.env.SQL_SERVER;
  const database = process.env.SQL_DATABASE;
  if (!server || !database) {
    return null;
  }
  return {
    server,
    database,
    authentication: {
      // Uses the App Service MSI endpoint; no secret, tokens auto-refresh.
      type: 'azure-active-directory-msi-app-service',
    },
    options: {
      encrypt: true,
      trustServerCertificate: false,
    },
    // Serverless free-tier DB auto-pauses; allow time for a cold resume.
    connectionTimeout: 30000,
  };
}

function getPool() {
  const config = buildConfig();
  if (!config) {
    return null;
  }
  if (!poolPromise) {
    poolPromise = new sql.ConnectionPool(config)
      .connect()
      .catch((err) => {
        // Reset so a later request can retry (free-tier SQL auto-pauses/resumes).
        poolPromise = null;
        throw err;
      });
  }
  return poolPromise;
}

// Returns database connectivity info for the "/" page.
// Never throws — a missing/paused DB degrades gracefully to { connected: false }.
async function getDbInfo() {
  const pool = getPool();
  if (!pool) {
    return { connected: false, detail: 'SQL_SERVER / SQL_DATABASE not configured' };
  }
  try {
    const p = await pool;
    const result = await p
      .request()
      .query('SELECT SUSER_SNAME() AS who, GETUTCDATE() AS server_time');
    const row = result.recordset[0];
    return { connected: true, who: row.who, serverTime: row.server_time };
  } catch (err) {
    return { connected: false, detail: err.message };
  }
}

module.exports = { getDbInfo };
