import { prisma } from './prisma/client';

async function main() {
  console.log('🌱 Seeding Lenses, Frames, and Solutions for Bausch & Lomb India...');

  const vendorId = '4bab1cd4-4109-48b4-9f73-08895ab43b4a';

  const items = [
    // Lenses
    {
      sku: 'BL-LENS-001',
      name: 'Bausch & Lomb ULTRA HD Single Vision Lens',
      kind: 'LENS' as any,
      stockQuantity: 100,
      reorderLevel: 15,
      vendorId: vendorId,
    },
    {
      sku: 'BL-LENS-002',
      name: 'Bausch & Lomb Biotrue Advanced Progressive Lens',
      kind: 'LENS' as any,
      stockQuantity: 75,
      reorderLevel: 10,
      vendorId: vendorId,
    },
    {
      sku: 'BL-LENS-003',
      name: 'Bausch & Lomb Xenon Smart Blue-Cut Lens',
      kind: 'LENS' as any,
      stockQuantity: 110,
      reorderLevel: 20,
      vendorId: vendorId,
    },
    // Frames
    {
      sku: 'BL-FRAME-001',
      name: 'Bausch & Lomb Active Sport Titanium Frame',
      kind: 'FRAME' as any,
      stockQuantity: 30,
      reorderLevel: 5,
      vendorId: vendorId,
    },
    {
      sku: 'BL-FRAME-002',
      name: 'Bausch & Lomb Premium Slim Acetate Frame',
      kind: 'FRAME' as any,
      stockQuantity: 25,
      reorderLevel: 5,
      vendorId: vendorId,
    },
    {
      sku: 'BL-FRAME-003',
      name: 'Bausch & Lomb Retro Aviator Metal Frame',
      kind: 'FRAME' as any,
      stockQuantity: 40,
      reorderLevel: 8,
      vendorId: vendorId,
    },
    // Solutions
    {
      sku: 'BL-SOL-001',
      name: 'Bausch & Lomb ReNu Fresh Multi-Purpose Solution',
      kind: 'ACCESSORY' as any,
      stockQuantity: 150,
      reorderLevel: 20,
      vendorId: vendorId,
    },
    {
      sku: 'BL-SOL-002',
      name: 'Bausch & Lomb Biotrue Hydration Lens Solution',
      kind: 'ACCESSORY' as any,
      stockQuantity: 90,
      reorderLevel: 15,
      vendorId: vendorId,
    },
    {
      sku: 'BL-SOL-003',
      name: 'Bausch & Lomb Boston Advance Gas Permeable Solution',
      kind: 'ACCESSORY' as any,
      stockQuantity: 65,
      reorderLevel: 10,
      vendorId: vendorId,
    }
  ];

  for (const item of items) {
    await prisma.inventoryProduct.upsert({
      where: { sku: item.sku },
      update: item,
      create: item,
    });
  }

  console.log('✅ Successfully seeded all 9 catalog products for Bausch & Lomb India!');
}

main()
  .catch((e) => console.error('❌ Error during seeding:', e))
  .finally(() => prisma.$disconnect());
