import { prisma } from './prisma/client';

async function main() {
  const sku = 'PROD-LENS-001';
  
  console.log(`Locating product with SKU: ${sku}`);
  const product = await prisma.inventoryProduct.findUnique({
    where: { sku }
  });

  if (!product) {
    console.error('Product not found! Please create the product via the app first.');
    return;
  }

  console.log(`Found product: ${product.name} (ID: ${product.id}). Proceeding with override.`);

  // 1. Remove old movements so we start fresh with this test distribution
  const deleteResult = await prisma.inventoryMovement.deleteMany({
    where: { productId: product.id }
  });
  console.log(`Deleted ${deleteResult.count} previous stock movements.`);

  // Calculate Date 6 months ago
  const sixMonthsAgo = new Date();
  sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);

  const today = new Date();

  // 2. Insert 50 stock batch 6 months old
  await prisma.inventoryMovement.create({
    data: {
      productId: product.id,
      quantity: 50,
      reason: 'Old Stock Entry',
      createdAt: sixMonthsAgo
    }
  });
  console.log('Created batch of 50 units timestamped 6 months ago.');

  // 3. Insert 100 stock batch today
  await prisma.inventoryMovement.create({
    data: {
      productId: product.id,
      quantity: 100,
      reason: 'New Received Stock',
      createdAt: today
    }
  });
  console.log('Created batch of 100 units timestamped today.');

  // 4. Ensure total matches 150
  await prisma.inventoryProduct.update({
    where: { id: product.id },
    data: { stockQuantity: 150 }
  });
  console.log('Updated total product stock counter to 150.');

  console.log('SUCCESS: Inventory distributed as requested.');
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });
