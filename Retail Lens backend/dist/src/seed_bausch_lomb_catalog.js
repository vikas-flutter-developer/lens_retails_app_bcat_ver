"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("./prisma/client");
async function main() {
    console.log('🌱 Seeding Lenses, Frames, and Solutions for Bausch & Lomb India...');
    const vendorId = '4bab1cd4-4109-48b4-9f73-08895ab43b4a';
    const items = [
        {
            sku: 'BL-LENS-001',
            name: 'Bausch & Lomb ULTRA HD Single Vision Lens',
            kind: 'LENS',
            stockQuantity: 100,
            reorderLevel: 15,
            vendorId: vendorId,
        },
        {
            sku: 'BL-LENS-002',
            name: 'Bausch & Lomb Biotrue Advanced Progressive Lens',
            kind: 'LENS',
            stockQuantity: 75,
            reorderLevel: 10,
            vendorId: vendorId,
        },
        {
            sku: 'BL-LENS-003',
            name: 'Bausch & Lomb Xenon Smart Blue-Cut Lens',
            kind: 'LENS',
            stockQuantity: 110,
            reorderLevel: 20,
            vendorId: vendorId,
        },
        {
            sku: 'BL-FRAME-001',
            name: 'Bausch & Lomb Active Sport Titanium Frame',
            kind: 'FRAME',
            stockQuantity: 30,
            reorderLevel: 5,
            vendorId: vendorId,
        },
        {
            sku: 'BL-FRAME-002',
            name: 'Bausch & Lomb Premium Slim Acetate Frame',
            kind: 'FRAME',
            stockQuantity: 25,
            reorderLevel: 5,
            vendorId: vendorId,
        },
        {
            sku: 'BL-FRAME-003',
            name: 'Bausch & Lomb Retro Aviator Metal Frame',
            kind: 'FRAME',
            stockQuantity: 40,
            reorderLevel: 8,
            vendorId: vendorId,
        },
        {
            sku: 'BL-SOL-001',
            name: 'Bausch & Lomb ReNu Fresh Multi-Purpose Solution',
            kind: 'ACCESSORY',
            stockQuantity: 150,
            reorderLevel: 20,
            vendorId: vendorId,
        },
        {
            sku: 'BL-SOL-002',
            name: 'Bausch & Lomb Biotrue Hydration Lens Solution',
            kind: 'ACCESSORY',
            stockQuantity: 90,
            reorderLevel: 15,
            vendorId: vendorId,
        },
        {
            sku: 'BL-SOL-003',
            name: 'Bausch & Lomb Boston Advance Gas Permeable Solution',
            kind: 'ACCESSORY',
            stockQuantity: 65,
            reorderLevel: 10,
            vendorId: vendorId,
        }
    ];
    for (const item of items) {
        await client_1.prisma.inventoryProduct.upsert({
            where: { sku: item.sku },
            update: item,
            create: item,
        });
    }
    console.log('✅ Successfully seeded all 9 catalog products for Bausch & Lomb India!');
}
main()
    .catch((e) => console.error('❌ Error during seeding:', e))
    .finally(() => client_1.prisma.$disconnect());
//# sourceMappingURL=seed_bausch_lomb_catalog.js.map