const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const targetSku = 'PROD-LENS-001';
  console.log(`🔍 Fetching base product metadata for ${targetSku}...`);
  
  const base = await prisma.inventoryProduct.findUnique({
    where: { sku: targetSku }
  });
  
  if (!base) {
    console.error(`❌ Could not find product with SKU ${targetSku}. Aborting.`);
    return;
  }

  const variations = [
    {
      suffix: '-GP2',
      stock: 80,
      power: {
        rightEye: { sphFrom: "2", sphTo: "4", cylFrom: "0", cylTo: "1", axis: "180", qty: 1 },
        leftEye: { sphFrom: "2", sphTo: "4", cylFrom: "0", cylTo: "1", axis: "180", qty: 1 }
      }
    },
    {
      suffix: '-GP3',
      stock: 110,
      power: {
        rightEye: { sphFrom: "-2", sphTo: "0", cylFrom: "0", cylTo: "0.5", axis: "90", qty: 1 },
        leftEye: { sphFrom: "-2", sphTo: "0", cylFrom: "0", cylTo: "0.5", axis: "90", qty: 1 }
      }
    },
    {
      suffix: '-GP4',
      stock: 50,
      power: {
        rightEye: { sphFrom: "4", sphTo: "6", cylFrom: "1", cylTo: "2", axis: "180", qty: 1 },
        leftEye: { sphFrom: "4", sphTo: "6", cylFrom: "1", cylTo: "2", axis: "180", qty: 1 }
      }
    }
  ];

  console.log('📝 Cloning database record into 3 new power variations...');

  for (const variant of variations) {
    const newSku = `${base.sku}${variant.suffix}`;
    try {
      await prisma.inventoryProduct.create({
        data: {
          sku: newSku,
          name: base.name, // Keep exact same name for grouping
          kind: base.kind,
          stockQuantity: variant.stock,
          reorderLevel: base.reorderLevel,
          salePrice: base.salePrice,
          vendorId: base.vendorId,
          powerSpecs: variant.power
        }
      });
      console.log(`✅ Created Power Group Variant: ${newSku}`);
    } catch (err) {
       if (err.code === 'P2002') {
          console.log(`⏩ Variant ${newSku} already exists in DB. Skipping creation.`);
       } else {
          throw err;
       }
    }
  }
  
  console.log('\n✨ Done! 3 new variations were injected successfully.');
}

main()
  .catch(e => console.error('❌ Unexpected error:', e))
  .finally(async () => {
    await prisma.$disconnect();
  });
