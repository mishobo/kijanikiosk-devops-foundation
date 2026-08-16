'use strict';

const { readObject, writeObject, recordsFromEvent, log } = require('./s3local');

const NOTIFICATIONS_BUCKET = process.env.NOTIFICATIONS_BUCKET || `kijani-payments-notifications-${process.env.STAGE || 'dev'}`;
const TAX_RATE = 0.16; // Kenya VAT, matches the rate used in Week 10 course examples.

// kk-processor: fires on every object written to the processed bucket by
// kk-receipts. Enriches the receipt with a tax line and forwards it to the
// notifications bucket for kk-notifier.
async function handler(event) {
  const results = [];

  for (const { bucket, key } of recordsFromEvent(event)) {
    const receipt = readObject(bucket, key);

    const tax = Math.round(receipt.total * TAX_RATE * 100) / 100;
    const enriched = {
      ...receipt,
      tax,
      totalWithTax: Math.round((receipt.total + tax) * 100) / 100,
      processedAt: new Date().toISOString(),
    };

    writeObject(NOTIFICATIONS_BUCKET, key, enriched);
    log({ service: 'kk-processor', level: 'info', event: 'receipt_enriched', orderId: receipt.orderId, tax, from: bucket, to: NOTIFICATIONS_BUCKET });
    results.push(receipt.orderId);
  }

  return { statusCode: 200, processed: results };
}

module.exports = { handler };
