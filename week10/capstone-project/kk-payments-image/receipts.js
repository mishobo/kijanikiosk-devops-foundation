'use strict';

const fs = require('fs');
const path = require('path');

// Local stand-in for S3 PutObject, matching the course convention of
// mocking S3 with a directory tree under S3_LOCAL_ROOT (default
// /tmp/kijani-s3-local/<bucket>/<key>). The serverless kk-receipts function
// watches this same root, so writing a file here is what "fires" the chain.
const S3_LOCAL_ROOT = process.env.S3_LOCAL_ROOT || '/tmp/kijani-s3-local';

function writeReceipt(bucket, order) {
  const bucketDir = path.join(S3_LOCAL_ROOT, bucket);
  fs.mkdirSync(bucketDir, { recursive: true });

  const key = `receipt-${order.orderId}.json`;
  const body = JSON.stringify(order, null, 2);
  fs.writeFileSync(path.join(bucketDir, key), body);

  return { bucket, key };
}

module.exports = { writeReceipt, S3_LOCAL_ROOT };
