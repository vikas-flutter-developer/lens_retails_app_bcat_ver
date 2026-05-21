import { prisma } from './prisma/client';

async function main() {
  console.log('Adjusting recent inventory movement date back by 1 day...');
  
  const sku = 'PROD-LENS-001';
  const product = await prisma.inventoryProduct.findUnique({ where: { sku } });
  
  if (!product) {
    console.error('Product not found!');
    return;
  }

  const latest = await prisma.inventoryMovement.findFirst({
    where: { productId: product.id, quantity: 100 },
    orderBy: { createdAt: 'desc' }
  });

  if (!latest) {
    console.error('Target movement of +100 not found.');
    return;
  }

  const yesterday = new Date(latest.createdAt);
  yesterday.setDate(yesterday.getDate() - 1);

  await prisma.inventoryMovement.update({
    where: { id: latest.id },
    data: { createdAt: yesterday }
  });

  console.log(`SUCCESS: Updated date from ${latest.createdAt.toISOString()} to ${yesterday.toISOString()}`);
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
