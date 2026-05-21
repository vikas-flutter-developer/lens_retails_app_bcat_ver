const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function count() {
  const totalLenses = await prisma.inventoryProduct.count({
    where: { kind: 'LENS' }
  });
  
  const leftOnly = await prisma.inventoryProduct.count({
    where: { kind: 'LENS', sku: { endsWith: '-L' } }
  });

  const rightOnly = await prisma.inventoryProduct.count({
    where: { kind: 'LENS', sku: { endsWith: '-R' } }
  });

  const bothSame = await prisma.inventoryProduct.count({
    where: { kind: 'LENS', sku: { endsWith: '-SAME' } }
  });

  const bothDiff = await prisma.inventoryProduct.count({
    where: { kind: 'LENS', sku: { endsWith: '-DIFF' } }
  });

  console.log('📊 --- FINAL DATABASE INVENTORY COUNT ---');
  console.log(`Total Lenses in Database: ${totalLenses}`);
  console.log(`- Left Only (-L):       ${leftOnly}`);
  console.log(`- Right Only (-R):      ${rightOnly}`);
  console.log(`- Both Same (-SAME):    ${bothSame}`);
  console.log(`- Both Diff (-DIFF):    ${bothDiff}`);
  console.log(`- Base / Original:      ${totalLenses - (leftOnly + rightOnly + bothSame + bothDiff)}`);
  console.log('-----------------------------------------');
}

count()
  .catch(console.error)
  .finally(async () => await prisma.$disconnect());
