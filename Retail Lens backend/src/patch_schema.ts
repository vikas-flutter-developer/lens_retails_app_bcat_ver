import { prisma } from './prisma/client';

async function main() {
  console.log('Executing targeted safe SQL to append power_specs column...');
  try {
    // Direct SQL Alter avoiding full database sync issues
    const result = await prisma.$executeRawUnsafe(
      `ALTER TABLE "InventoryProduct" ADD COLUMN IF NOT EXISTS "power_specs" JSONB;`
    );
    console.log('✅ Success. Column added or already present.', result);
  } catch (err) {
    console.error('❌ SQL Failed:', err);
  }
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
