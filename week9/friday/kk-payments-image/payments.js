'use strict';

function calculateTotal(items) {
  if (!Array.isArray(items)) {
    throw new TypeError('Items must be an array');
  }
  return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
}

function formatCurrency(amount, currency = 'KES') {
  return `${currency} ${amount.toFixed(2)}`;
}

module.exports = { calculateTotal, formatCurrency };
