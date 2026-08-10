'use strict';

const http = require('http');
const { calculateTotal, formatCurrency } = require('./payments');

// The app honours APP_PORT (from the ConfigMap) and falls back to PORT, then 3001.
const PORT = parseInt(process.env.APP_PORT || process.env.PORT || '3001', 10);
const APP_VERSION = process.env.APP_VERSION || require('./package.json').version;
const NODE_ENV = process.env.NODE_ENV || 'unknown';
const startedAt = Date.now();

const server = http.createServer((req, res) => {
  const path = req.url.split('?')[0];

  // Health endpoint used by the readiness and liveness probes.
  if (path === '/health' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status: 'ok',
      service: 'kk-payments',
      version: APP_VERSION,
      environment: NODE_ENV,
      uptime_seconds: Math.floor((Date.now() - startedAt) / 1000),
    }));
    return;
  }

  // Service root — returns 200 so the Ingress /payments/ route is reachable.
  if (path === '/' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ service: 'kk-payments', version: APP_VERSION, status: 'ok' }));
    return;
  }

  if (path === '/quote' && req.method === 'GET') {
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
  console.log(`kk-payments ${APP_VERSION} (${NODE_ENV}) listening on port ${PORT}`);
});

const shutdown = (signal) => {
  console.log(`received ${signal}, shutting down`);
  server.close(() => process.exit(0));
};
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
