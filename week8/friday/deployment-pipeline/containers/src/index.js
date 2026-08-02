'use strict';

const { calculateTotal, formatCurrency } = require('./payments');

function main() {
  const items = [
    { name: 'Sample Item', price: 100, quantity: 2 },
  ];
  const total = calculateTotal(items);
  console.log(`Order total: ${formatCurrency(total)}`);
}

if (require.main === module) {
  main();
}

module.exports = { main };
