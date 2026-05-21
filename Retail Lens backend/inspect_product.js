const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function inspect() {
  const sku = 'PROD-LENS-001-GP4';
  console.log('🔍 Querying details for:', sku);
  
  const product = await prisma.inventoryProduct.findUnique({
    where: { sku: sku },
    include: {
      units: true
    }
  });

  if (product) {
    console.log('\n=== INVENTORY PRODUCT ===');
    console.log('ID:', product.id);
    console.log('SKU:', product.sku);
    console.log('Name:', product.name);
    console.log('Kind:', product.kind);
    console.log('Stock Quantity:', product.stockQuantity);
    
    console.log('\n=== INDIVIDUAL UNITS (SERIALIZED) ===');
    if (product.units && product.units.length > 0) {
      console.log(`Found ${product.units.length} serialized units:`);
      product.units.forEach((unit, i) => {
        console.log(`  Unit ${i + 1}: ID=${unit.id}, uniqueQrCode="${unit.uniqueQrCode}", status=${unit.status}`);
      });
    } else {
      console.log('No serialized units found for this product. It is tracked by bulk SKU.');
    }
  } else {
    console.log('❌ Product not found in database.');
  }
}

inspect()
  .catch(console.error)
  .finally(async () => {
    await prisma.$disconnect();
  });
