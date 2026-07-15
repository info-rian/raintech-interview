'use strict';

const express = require('express');
const { getDbInfo } = require('./db');

function createApp() {
  const app = express();

  // Liveness probe consumed by App Service health check (health_check_path=/healthz).
  // Kept independent of the database on purpose: a paused free-tier SQL server
  // must not make App Service recycle an otherwise-healthy instance.
  app.get('/healthz', (req, res) => {
    res.status(200).json({ status: 'ok', uptime: process.uptime() });
  });

  // Landing page: Hello World + a live read from Azure SQL to prove the
  // end-to-end path (App Service -> Key Vault reference -> SQL).
  app.get('/', async (req, res) => {
    const database = await getDbInfo();
    res.status(200).json({
      message: 'Rian Septiana - Raintech DevOps Engineer Technical test!!👋',
      environment: process.env.APP_ENVIRONMENT || 'unknown',
      commit: process.env.APP_COMMIT_SHA || 'dev',
      database,
    });
  });

  return app;
}

if (require.main === module) {
  // App Service for Linux injects PORT (commonly 8080); default for local dev.
  const port = process.env.PORT || 3000;
  createApp().listen(port, () => {
    // eslint-disable-next-line no-console
    console.log(`hello-azure-appservice listening on :${port}`);
  });
}

module.exports = { createApp };
