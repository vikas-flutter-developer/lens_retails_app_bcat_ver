import { prisma } from './prisma/client';

async function main() {
  console.log('🔗 Updating all products inside your database with custom premium prices...');

  const prices: Record<string, number> = {
    // B&L Lenses
    'BL-LENS-001': 1800.00,
    'BL-LENS-002': 3500.00,
    'BL-LENS-003': 2200.00,
    // Other Lenses
    'PROD-LENS-001': 1500.00,
    'PROD-LENS-002': 4800.00,
    'PROD-LENS-003': 5500.00,
    'PROD-LENS-005': 6200.00,
    'PROD-LENS-LOW': 2800.00,

    // B&L Frames
    'BL-FRAME-001': 4200.00,
    'BL-FRAME-002': 2900.00,
    'BL-FRAME-003': 3200.00,
    // Other Frames
    'PROD-FRAME-001': 8500.00,
    'PROD-FRAME-002': 12000.00,
    'PROD-FRAME-003': 14500.00,
    'PROD-FRAME-LOW': 18500.00,
    'PROD-FRAME-005': 6800.00,
    'PROD-FRAM-101': 5200.00,
    'SKU001': 1100.00,

    // Contact Lenses
    'PROD-CL-001': 1600.00,
    'PROD-CL-002': 2400.00,
    'PROD-CL-003': 3800.00,
    'PROD-CL-004': 4100.00,
    'PROD-CL-005': 1950.00,

    // Solutions & Accessories
    'BL-SOL-001': 450.00,
    'BL-SOL-002': 650.00,
    'BL-SOL-003': 850.00,
    'PROD-ACC-LOW': 150.00
  };

  let updatedCount = 0;
  for (const [sku, price] of Object.entries(prices)) {
    const updated = await prisma.inventoryProduct.updateMany({
      where: { sku },
      data: { salePrice: price }
    });
    updatedCount += updated.count;
  }

  console.log(`✅ Successfully updated ${updatedCount} products with their correct custom prices!`);
}

main()
  .catch((e) => console.error('❌ Error updating product prices:', e))
  .finally(() => prisma.$disconnect());
