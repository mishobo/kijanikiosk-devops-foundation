'use strict';

const { readObject, writeObject, recordsFromEvent, log } = require('./s3local');

const PROCESSED_BUCKET = process.env.PROCESSED_BUCKET || `kijani-payments-processed-${process.env.STAGE || 'dev'}`;

// kk-receipts: fires on every object written to the receipts bucket by
// kk-payments. Validates the receipt shape and forwards it, unchanged, to
// the processed bucket for kk-processor.
async function handler(event) {
  const results = [];

  for (const { bucket, key } of recordsFromEvent(event)) {
    const receipt = readObject(bucket, key);

    if (!receipt.orderId || !receipt.total || !Array.isArray(receipt.items)) {
      log({ service: 'kk-receipts', level: 'error', event: 'invalid_receipt', bucket, key });
      continue;
    }

    writeObject(PROCESSED_BUCKET, key, { ...receipt, receivedAt: new Date().toISOString() });
    log({ service: 'kk-receipts', level: 'info', event: 'receipt_forwarded', orderId: receipt.orderId, from: bucket, to: PROCESSED_BUCKET });
    results.push(receipt.orderId);
  }

  return { statusCode: 200, forwarded: results };
}

module.exports = { handler };
