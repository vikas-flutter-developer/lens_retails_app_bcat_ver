import { prisma } from './prisma/client';

async function main() {
  console.log('🔗 Starting master mapping of all inventory products to their correct Vendor IDs...');

  const mappings = [
    // ESSILOR INDIA (id: '48ae535f-4c98-4090-b278-670baea36245')
    {
      vendorId: '48ae535f-4c98-4090-b278-670baea36245',
      skus: ['PROD-LENS-001', 'PROD-LENS-002', 'PROD-FRAME-001', 'PROD-FRAME-LOW']
    },
    // CARL ZEISS VISION (id: 'b11a0a51-bdfc-4104-b4ce-f383f678025e')
    {
      vendorId: 'b11a0a51-bdfc-4104-b4ce-f383f678025e',
      skus: ['PROD-LENS-003', 'PROD-LENS-LOW', 'PROD-FRAME-002', 'PROD-FRAME-003']
    },
    // LAWRENCE & MAYO (id: '5f243ef6-56df-4341-9bec-3914dfc725da')
    {
      vendorId: '5f243ef6-56df-4341-9bec-3914dfc725da',
      skus: ['PROD-FRAM-101', 'SKU001', 'PROD-ACC-LOW']
    }
  ];

  for (const mapping of mappings) {
    const updated = await prisma.inventoryProduct.updateMany({
      where: {
        sku: { in: mapping.skus }
      },
      data: {
        vendorId: mapping.vendorId
      }
    });
    console.log(`✅ Updated ${updated.count} SKUs for Vendor ID: ${mapping.vendorId}`);
  }

  console.log('🎉 Master inventory vendor mapping completed successfully!');
}

main()
  .catch((e) => console.error('❌ Error updating inventory vendors:', e))
  .finally(() => prisma.$disconnect());
