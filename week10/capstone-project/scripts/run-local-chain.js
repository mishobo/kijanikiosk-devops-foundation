#!/usr/bin/env node
'use strict';

// Local runtime for the kk-receipts -> kk-processor -> kk-notifier chain.
//
// This is the "local alternative" artifact referenced in project.md: it
// invokes the exact same handler modules serverless.yml points to, but
// triggers them by watching the local S3 mock directories with fs.watch
// instead of requiring a running `serverless offline` + serverless-s3-local
// stack. Use `npm run offline` in serverless/ instead if you want the real
// Serverless Framework runtime.
//
// Usage: node scripts/run-local-chain.js [stage]

const fs = require('fs');
const path = require('path');

const stage = process.argv[2] || process.env.STAGE || 'staging';
process.env.STAGE = stage;

const S3_LOCAL_ROOT = process.env.S3_LOCAL_ROOT || '/tmp/kijani-s3-local';
const receiptsBucket = `kijani-payments-receipts-${stage}`;
const processedBucket = `kijani-payments-processed-${stage}`;
const notificationsBucket = `kijani-payments-notifications-${stage}`;

process.env.PROCESSED_BUCKET = processedBucket;
process.env.NOTIFICATIONS_BUCKET = notificationsBucket;

const receipts = require('../serverless/handlers/receipts');
const processor = require('../serverless/handlers/processor');
const notifier = require('../serverless/handlers/notifier');

function ensureBucket(bucket) {
  const dir = path.join(S3_LOCAL_ROOT, bucket);
  fs.mkdirSync(dir, { recursive: true });
  return dir;
}

function watchBucket(bucket, handler, label) {
  const dir = ensureBucket(bucket);
  const seen = new Set(fs.readdirSync(dir)); // ignore files that already existed at startup

  fs.watch(dir, (eventType, filename) => {
    if (!filename || !filename.endsWith('.json') || seen.has(filename)) return;
    const filePath = path.join(dir, filename);
    if (!fs.existsSync(filePath)) return;

    seen.add(filename);
    const event = { Records: [{ s3: { bucket: { name: bucket }, object: { key: filename } } }] };

    handler(event)
      .then(() => console.log(`[run-local-chain] ${label} handled ${bucket}/${filename}`))
      .catch((err) => console.error(`[run-local-chain] ${label} FAILED on ${bucket}/${filename}:`, err.message));
  });

  console.log(`[run-local-chain] watching ${dir} (${label})`);
}

watchBucket(receiptsBucket, receipts.handler, 'kk-receipts');
watchBucket(processedBucket, processor.handler, 'kk-processor');
watchBucket(notificationsBucket, notifier.handler, 'kk-notifier');

console.log(`[run-local-chain] stage=${stage} root=${S3_LOCAL_ROOT} — waiting for kk-payments to write a receipt...`);
