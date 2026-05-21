const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function fixSpaces() {
  const products = await prisma.inventoryProduct.findMany();
  
  for (const p of products) {
    if (p.sku !== p.sku.trim()) {
      console.log(`Fixing SKU: [${p.sku}] -> [${p.sku.trim()}]`);
      await prisma.inventoryProduct.update({
        where: { id: p.id },
        data: { sku: p.sku.trim() }
      });
    }
  }
  console.log('Cleanup complete!');
}

fixSpaces()
  .catch(console.error)
  .finally(async () => {
    await prisma.$disconnect();
  });
