'use strict';

const http = require('http');
const { calculateTotal, formatCurrency } = require('./payments');

const PORT = parseInt(process.env.PORT || '3001', 10);
const APP_VERSION = process.env.APP_VERSION || require('../package.json').version;
const DEPLOY_ENV = process.env.DEPLOY_ENV || 'unknown';
const startedAt = Date.now();

const server = http.createServer((req, res) => {
  if (req.url === '/health' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status: 'ok',
      service: 'kk-payments',
      version: APP_VERSION,
      environment: DEPLOY_ENV,
      uptime_seconds: Math.floor((Date.now() - startedAt) / 1000),
    }));
    return;
  }

  if (req.url === '/quote' && req.method === 'GET') {
    const items = [{ name: 'Sample Item', price: 100, quantity: 2 }];
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      total: formatCurrency(calculateTotal(items)),
      version: APP_VERSION,
    }));
    return;
  }

  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: 'not found' }));
});

server.listen(PORT, () => {
  console.log(`kk-payments ${APP_VERSION} (${DEPLOY_ENV}) listening on port ${PORT}`);
});

const shutdown = (signal) => {
  console.log(`received ${signal}, shutting down`);
  server.close(() => process.exit(0));
};
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
