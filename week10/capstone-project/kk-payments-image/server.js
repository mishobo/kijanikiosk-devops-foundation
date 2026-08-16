'use strict';

const http = require('http');
const crypto = require('crypto');
const { calculateTotal, formatCurrency } = require('./payments');
const { writeReceipt } = require('./receipts');

// The app honours APP_PORT (from the ConfigMap) and falls back to PORT, then 3001.
const PORT = parseInt(process.env.APP_PORT || process.env.PORT || '3001', 10);
const APP_VERSION = process.env.APP_VERSION || require('./package.json').version;
const NODE_ENV = process.env.NODE_ENV || 'unknown';
const RECEIPTS_BUCKET = process.env.RECEIPTS_BUCKET || '';
const startedAt = Date.now();

// Structured JSON logging to stdout. One line per request, consumed by
// monitoring/error-rate.js (Week 7 SLO pattern) and readable by kubectl logs.
function logLine(fields) {
  console.log(JSON.stringify({ timestamp: new Date().toISOString(), service: 'kk-payments', environment: NODE_ENV, ...fields }));
}

const server = http.createServer((req, res) => {
  const path = req.url.split('?')[0];
  const start = Date.now();
  const correlationId = req.headers['x-correlation-id'] || crypto.randomUUID();

  function respond(status, body) {
    res.writeHead(status, { 'Content-Type': 'application/json', 'x-correlation-id': correlationId });
    res.end(JSON.stringify(body));
    logLine({
      level: status >= 500 ? 'error' : 'info',
      endpoint: path,
      method: req.method,
      status_code: status,
      duration_ms: Date.now() - start,
      correlation_id: correlationId,
    });
  }

  // Health endpoint used by the readiness and liveness probes.
  if (path === '/health' && req.method === 'GET') {
    respond(200, {
      status: 'ok',
      service: 'kk-payments',
      version: APP_VERSION,
      environment: NODE_ENV,
      uptime_seconds: Math.floor((Date.now() - startedAt) / 1000),
    });
    return;
  }

  // Service root — returns 200 so the Ingress /payments/ route is reachable.
  if (path === '/' && req.method === 'GET') {
    respond(200, { service: 'kk-payments', version: APP_VERSION, status: 'ok' });
    return;
  }

  if (path === '/quote' && req.method === 'GET') {
    const items = [{ name: 'Sample Item', price: 100, quantity: 2 }];
    respond(200, { total: formatCurrency(calculateTotal(items)), version: APP_VERSION });
    return;
  }

  // Completes a payment and writes a receipt event to the S3 receipts
  // bucket for the current environment. This is the integration seam
  // between the Kubernetes runtime layer and the serverless receipt chain.
  if (path === '/pay' && req.method === 'POST') {
    let raw = '';
    req.on('data', (chunk) => { raw += chunk; });
    req.on('end', () => {
      let items;
      try {
        const parsed = raw ? JSON.parse(raw) : {};
        items = Array.isArray(parsed.items) && parsed.items.length > 0
          ? parsed.items
          : [{ name: 'Sample Item', price: 100, quantity: 1 }];
      } catch (err) {
        respond(400, { error: 'invalid JSON body' });
        return;
      }

      let total;
      try {
        total = calculateTotal(items);
      } catch (err) {
        respond(400, { error: err.message });
        return;
      }

      const orderId = crypto.randomUUID();
      const order = {
        orderId,
        correlationId,
        items,
        total,
        currency: 'KES',
        timestamp: new Date().toISOString(),
        environment: NODE_ENV,
      };

      if (!RECEIPTS_BUCKET) {
        respond(500, { error: 'RECEIPTS_BUCKET not configured' });
        return;
      }

      try {
        const { bucket, key } = writeReceipt(RECEIPTS_BUCKET, order);
        respond(201, { orderId, total: formatCurrency(total), receipt: { bucket, key } });
      } catch (err) {
        respond(500, { error: 'failed to write receipt' });
      }
    });
    return;
  }

  respond(404, { error: 'not found' });
});

server.listen(PORT, () => {
  console.log(`kk-payments ${APP_VERSION} (${NODE_ENV}) listening on port ${PORT}, receipts bucket=${RECEIPTS_BUCKET || '(none)'}`);
});

const shutdown = (signal) => {
  console.log(`received ${signal}, shutting down`);
  server.close(() => process.exit(0));
};
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
