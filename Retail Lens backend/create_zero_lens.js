const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function createZeroStockLens() {
  console.log('🚀 Preparing to inject Zero Stock testing product...');

  const sku = 'TEST-LENS-ZERO';
  const name = 'Anti-Reflective Blue-Cut Lens (ZERO STOCK FOR TESTING)';

  const powerSpecs = {
    leftEye: {
      sphFrom: "1",
      sphTo: "2",
      cylFrom: "1",
      cylTo: "2",
      axis: "180",
      addFrom: "1",
      addTo: "2",
      qty: 1
    },
    rightEye: {
      sphFrom: "1",
      sphTo: "2",
      cylFrom: "1",
      cylTo: "2",
      axis: "180",
      addFrom: "1",
      addTo: "2",
      qty: 1
    }
  };

  try {
    const product = await prisma.inventoryProduct.upsert({
      where: { sku: sku },
      update: {
        name: name,
        stockQuantity: 0, // Explicitly 0
        powerSpecs: powerSpecs,
        salePrice: 1500.0,
        reorderLevel: 10
      },
      create: {
        sku: sku,
        name: name,
        kind: 'LENS',
        stockQuantity: 0, // Explicitly 0
        salePrice: 1500.0,
        reorderLevel: 10,
        powerSpecs: powerSpecs
      }
    });

    console.log('\n✅ Successfully Created / Reset Test Lens:');
    console.log(`   📦 SKU:   ${product.sku}`);
    console.log(`   🏷️ Name:  ${product.name}`);
    console.log(`   📊 Stock: ${product.stockQuantity} Pcs (ZERO)`);
    console.log(`   💸 Price: ₹${product.salePrice}`);

  } catch (err) {
    console.error('❌ Error during Database injection:', err.message);
  }
}

createZeroStockLens()
  .catch(console.error)
  .finally(async () => await prisma.$disconnect());
