import { prisma } from './prisma/client';

async function main() {
  console.log('🔍 Fetching all items from the live database...');
  const products = await prisma.inventoryProduct.findMany({
    include: {
      vendor: true
    }
  });
  console.log(`📊 TOTAL ITEMS FOUND: ${products.length}\n`);
  console.log(JSON.stringify(products, null, 2));
}

main()
  .catch((e) => console.error('❌ Error:', e))
  .finally(() => prisma.$disconnect());
