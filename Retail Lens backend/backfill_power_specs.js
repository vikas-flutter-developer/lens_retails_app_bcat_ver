const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('🔍 Connecting to Database...');
  
  const lenses = await prisma.inventoryProduct.findMany({
    where: {
      kind: 'LENS'
    }
  });

  console.log(`📊 Found ${lenses.length} total lens items in the database.`);

  // Standard safe default power specs
  const defaultPower = {
    rightEye: { sphFrom: "1", sphTo: "2", cylFrom: "1", cylTo: "2", axis: "180", qty: 1 },
    leftEye: { sphFrom: "1", sphTo: "2", cylFrom: "1", cylTo: "2", axis: "180", qty: 1 }
  };

  let updateCount = 0;

  for (const lens of lenses) {
    const hasSpecs = lens.powerSpecs && typeof lens.powerSpecs === 'object' && Object.keys(lens.powerSpecs).length > 0;
    
    if (!hasSpecs) {
       await prisma.inventoryProduct.update({
         where: { id: lens.id },
         data: { powerSpecs: defaultPower }
       });
       console.log(`✅ Migrated Power Specs for: ${lens.name} (SKU: ${lens.sku})`);
       updateCount++;
    } else {
      console.log(`⏩ Skipped (already has specs): ${lens.name}`);
    }
  }

  console.log(`\n✨ SUCCESS: Backfilled power ranges for ${updateCount} lenses!`);
}

main()
  .catch(e => {
    console.error('❌ Runtime Error occurred:');
    console.error(e);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
