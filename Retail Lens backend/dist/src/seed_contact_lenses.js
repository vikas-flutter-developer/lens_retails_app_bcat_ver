"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("./prisma/client");
async function main() {
    console.log('🌱 Seeding premium Contact Lens products into the live database...');
    const items = [
        {
            sku: 'PROD-CL-001',
            name: 'Bausch & Lomb BioTrue Monthly Contact Lens',
            kind: 'ACCESSORY',
            stockQuantity: 35,
            reorderLevel: 5,
        },
        {
            sku: 'PROD-CL-002',
            name: 'Acuvue Moist 1-Day Disposable Contact Lens',
            kind: 'ACCESSORY',
            stockQuantity: 50,
            reorderLevel: 8,
        },
        {
            sku: 'PROD-CL-003',
            name: 'Alcon Dailies Total 1 Premium Contact Lens',
            kind: 'ACCESSORY',
            stockQuantity: 40,
            reorderLevel: 10,
        }
    ];
    for (const item of items) {
        const existing = await client_1.prisma.inventoryProduct.findUnique({
            where: { sku: item.sku }
        });
        if (!existing) {
            const created = await client_1.prisma.inventoryProduct.create({
                data: item
            });
            console.log(`✅ Created product: ${created.name} (SKU: ${created.sku})`);
        }
        else {
            console.log(`⚠️ Product with SKU ${item.sku} already exists.`);
        }
    }
    console.log('🎉 Contact Lens seeding completed successfully!');
}
main()
    .catch((e) => console.error('❌ Error during seeding:', e))
    .finally(() => client_1.prisma.$disconnect());
//# sourceMappingURL=seed_contact_lenses.js.map