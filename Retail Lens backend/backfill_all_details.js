const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('🔍 Connecting to Database...');
  
  const products = await prisma.inventoryProduct.findMany();
  console.log(`📊 Found ${products.length} total inventory items in the database.`);

  let updateCount = 0;

  for (const item of products) {
    const salePrice = item.salePrice || 1200.0;
    // Set a realistic purchase price at 50% of the sale price
    const purchasePrice = Math.round(salePrice * 0.5);

    // Extract brand name from the name
    let brandName = 'General';
    const nameLower = item.name.toLowerCase();
    if (nameLower.includes('bausch & lomb') || nameLower.includes('bausch')) {
      brandName = 'Bausch & Lomb';
    } else if (nameLower.includes('acuvue')) {
      brandName = 'Acuvue';
    } else if (nameLower.includes('alcon')) {
      brandName = 'Alcon';
    } else if (nameLower.includes('zeiss')) {
      brandName = 'Carl Zeiss';
    } else if (nameLower.includes('ray-ban') || nameLower.includes('rayban')) {
      brandName = 'Ray-Ban';
    } else {
      // Use the first word or two of the product name as the brand
      const words = item.name.split(' ');
      if (words.length > 0) {
        brandName = words.slice(0, Math.min(words.length, 2)).join(' ');
      }
    }

    // Get current specs or initialize empty map
    let currentSpecs = {};
    if (item.powerSpecs) {
      currentSpecs = typeof item.powerSpecs === 'string'
        ? JSON.parse(item.powerSpecs)
        : { ...item.powerSpecs };
    }

    // Set universal properties
    currentSpecs.purchasePrice = purchasePrice;
    currentSpecs.brandName = brandName;

    // Set conditional properties based on kind
    if (item.kind === 'FRAME') {
      currentSpecs.modelNumber = currentSpecs.modelNumber || 'BL-FRAME-' + item.sku.split('-').pop();
      currentSpecs.frameSize = currentSpecs.frameSize || '54-17-140';
      currentSpecs.color = currentSpecs.color || 'Matte Black';
      currentSpecs.frameType = currentSpecs.frameType || 'Full';
    } else if (item.kind === 'LENS' || item.kind === 'CONTACT_LENS') {
      // Ensure default eye configurations are populated if missing
      if (!currentSpecs.rightEye) {
        currentSpecs.rightEye = { sphFrom: "1", sphTo: "2", cylFrom: "1", cylTo: "2", axis: "180", qty: 1 };
      }
      if (!currentSpecs.leftEye) {
        currentSpecs.leftEye = { sphFrom: "1", sphTo: "2", cylFrom: "1", cylTo: "2", axis: "180", qty: 1 };
      }
    }

    // Perform database update
    await prisma.inventoryProduct.update({
      where: { id: item.id },
      data: {
        powerSpecs: currentSpecs
      }
    });

    console.log(`✅ Rich data populated for: ${item.name} | Brand: ${brandName} | Purchase: ₹${purchasePrice} (Sale: ₹${salePrice})`);
    updateCount++;
  }

  console.log(`\n✨ SUCCESS: Enriched and backfilled ${updateCount} inventory items with rich specifications!`);
}

main()
  .catch(e => {
    console.error('❌ Runtime Error occurred:');
    console.error(e);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
