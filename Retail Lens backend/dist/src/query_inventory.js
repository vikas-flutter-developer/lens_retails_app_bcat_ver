"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("./prisma/client");
async function main() {
    console.log('🔍 Fetching all items from the live database...');
    const products = await client_1.prisma.inventoryProduct.findMany({
        include: {
            vendor: true
        }
    });
    console.log(`📊 TOTAL ITEMS FOUND: ${products.length}\n`);
    console.log(JSON.stringify(products, null, 2));
}
main()
    .catch((e) => console.error('❌ Error:', e))
    .finally(() => client_1.prisma.$disconnect());
//# sourceMappingURL=query_inventory.js.map