"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("./prisma/client");
async function main() {
    console.log('🔗 Linking seeded Contact Lenses to Bausch & Lomb India (ID: 4bab1cd4-4109-48b4-9f73-08895ab43b4a)...');
    const skus = ['PROD-CL-001', 'PROD-CL-002', 'PROD-CL-003'];
    const vendorId = '4bab1cd4-4109-48b4-9f73-08895ab43b4a';
    const updated = await client_1.prisma.inventoryProduct.updateMany({
        where: {
            sku: { in: skus }
        },
        data: {
            vendorId: vendorId
        }
    });
    console.log(`✅ Successfully linked ${updated.count} Contact Lenses to Bausch & Lomb India!`);
}
main()
    .catch((e) => console.error('❌ Error during update:', e))
    .finally(() => client_1.prisma.$disconnect());
//# sourceMappingURL=update_vendor_id.js.map