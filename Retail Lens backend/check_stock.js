const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkStock() {
  const sku = 'PROD-LENS-001-GP4';
  const product = await prisma.inventoryProduct.findFirst({
    where: { sku: sku }
  });

  console.log('\n--- DATABASE STOCK QUERY ---');
  if (product) {
    console.log(`Product SKU:    ${product.sku}`);
    console.log(`Product Name:   ${product.name}`);
    console.log(`Stock Quantity: ${product.stockQuantity} Pcs`);
  } else {
    console.log(`❌ Error: Product with SKU "${sku}" not found in Database.`);
  }
  console.log('-----------------------------\n');
}

checkStock()
  .catch(console.error)
  .finally(async () => {
    await prisma.$disconnect();
  });
