'use strict';

const fs = require('fs');
const path = require('path');

const S3_LOCAL_ROOT = process.env.S3_LOCAL_ROOT || '/tmp/kijani-s3-local';

function readObject(bucket, key) {
  const filePath = path.join(S3_LOCAL_ROOT, bucket, key);
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function writeObject(bucket, key, data) {
  const dir = path.join(S3_LOCAL_ROOT, bucket);
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, key), JSON.stringify(data, null, 2));
}

// Normalises both a real S3 event (from serverless-s3-local / AWS) and the
// synthetic event shape produced by scripts/run-local-chain.js so handlers
// don't need to know which runtime invoked them.
function recordsFromEvent(event) {
  return (event.Records || []).map((record) => ({
    bucket: record.s3.bucket.name,
    key: decodeURIComponent((record.s3.object.key || '').replace(/\+/g, ' ')),
  }));
}

function log(fields) {
  console.log(JSON.stringify({ timestamp: new Date().toISOString(), ...fields }));
}

module.exports = { S3_LOCAL_ROOT, readObject, writeObject, recordsFromEvent, log };
