const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function findVikas() {
  const products = await prisma.inventoryProduct.findMany({
    where: {
      name: {
        contains: 'Vikas Special Lens'
      }
    }
  });

  console.log('Results found:', products.length);
  products.forEach(p => {
    console.log(`- ID: "${p.id}"`);
    console.log(`  SKU: [${p.sku}] (Length: ${p.sku.length})`);
    console.log(`  Name: "${p.name}"`);
  });
}

findVikas()
  .catch(console.error)
  .finally(async () => {
    await prisma.$disconnect();
  });
