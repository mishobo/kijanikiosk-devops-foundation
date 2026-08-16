'use strict';

const { readObject, recordsFromEvent, log } = require('./s3local');

// kk-notifier: fires on every object written to the notifications bucket by
// kk-processor. This is the end of the chain — in production it would send
// an SMS/email receipt; here it logs a structured summary that closes the
// loop kk-payments -> kk-receipts -> kk-processor -> kk-notifier.
async function handler(event) {
  const results = [];

  for (const { bucket, key } of recordsFromEvent(event)) {
    const receipt = readObject(bucket, key);

    log({
      service: 'kk-notifier',
      level: 'info',
      event: 'receipt_notified',
      orderId: receipt.orderId,
      total: receipt.total,
      totalWithTax: receipt.totalWithTax,
      currency: receipt.currency,
      correlationId: receipt.correlationId,
      chainLatencyMs: new Date() - new Date(receipt.timestamp),
    });
    results.push(receipt.orderId);
  }

  return { statusCode: 200, notified: results };
}

module.exports = { handler };
