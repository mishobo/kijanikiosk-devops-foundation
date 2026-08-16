#!/usr/bin/env node
'use strict';

// Log-based error rate monitoring for kk-payments (Track A Option B —
// prometheus.io alerting_rules pattern applied to structured logs instead
// of a running Prometheus instance, following the Week 7 SLO pattern).
//
// Reads newline-delimited JSON log lines from stdin (each line matches the
// shape server.js's logLine() writes: { timestamp, status_code, ... }),
// keeps only lines within the trailing WINDOW_SECONDS, and fires the same
// condition a Prometheus rule would:
//
//   sum(rate(http_requests_total{status=~"5.."}[2m]))
//     / sum(rate(http_requests_total[2m])) > 0.05
//
// Usage:
//   kubectl logs deployment/kk-payments -n kijani-project --since=5m \
//     | node monitoring/error-rate.js
//
// Writes monitoring/error-rate-summary.json and exits 1 when the alert
// condition is met, so it can be used as a Jenkins pipeline gate.

const fs = require('fs');
const path = require('path');

const WINDOW_SECONDS = parseInt(process.env.ERROR_RATE_WINDOW_SECONDS || '120', 10);
const THRESHOLD = parseFloat(process.env.ERROR_RATE_THRESHOLD || '0.05');
const SUMMARY_PATH = process.env.ERROR_RATE_SUMMARY_PATH || path.join(__dirname, 'error-rate-summary.json');

function readLines(stream) {
  return new Promise((resolve) => {
    let data = '';
    stream.on('data', (chunk) => { data += chunk; });
    stream.on('end', () => resolve(data.split('\n').filter(Boolean)));
  });
}

async function main() {
  const lines = await readLines(process.stdin);
  const now = Date.now();
  const windowStart = now - WINDOW_SECONDS * 1000;

  let total = 0;
  let errors = 0;
  let skipped = 0;

  for (const line of lines) {
    let entry;
    try {
      entry = JSON.parse(line);
    } catch (err) {
      skipped += 1;
      continue;
    }
    if (!entry.status_code || !entry.timestamp) continue;

    const ts = Date.parse(entry.timestamp);
    if (Number.isNaN(ts) || ts < windowStart) continue;

    total += 1;
    if (entry.status_code >= 500) errors += 1;
  }

  const errorRate = total === 0 ? 0 : errors / total;
  const alert = total > 0 && errorRate > THRESHOLD;

  const summary = {
    generatedAt: new Date(now).toISOString(),
    windowSeconds: WINDOW_SECONDS,
    threshold: THRESHOLD,
    totalRequests: total,
    errorRequests: errors,
    errorRate: Number(errorRate.toFixed(4)),
    skippedLines: skipped,
    alert,
    alertReason: alert
      ? `error rate ${(errorRate * 100).toFixed(1)}% exceeded ${(THRESHOLD * 100).toFixed(0)}% over the last ${WINDOW_SECONDS}s`
      : null,
  };

  fs.writeFileSync(SUMMARY_PATH, JSON.stringify(summary, null, 2));
  console.log(JSON.stringify(summary, null, 2));

  process.exit(alert ? 1 : 0);
}

main();
