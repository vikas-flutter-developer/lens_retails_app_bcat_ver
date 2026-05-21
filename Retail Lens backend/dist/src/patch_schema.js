"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("./prisma/client");
async function main() {
    console.log('Executing targeted safe SQL to append power_specs column...');
    try {
        const result = await client_1.prisma.$executeRawUnsafe(`ALTER TABLE "InventoryProduct" ADD COLUMN IF NOT EXISTS "power_specs" JSONB;`);
        console.log('✅ Success. Column added or already present.', result);
    }
    catch (err) {
        console.error('❌ SQL Failed:', err);
    }
}
main()
    .then(async () => {
    await client_1.prisma.$disconnect();
})
    .catch(async (e) => {
    console.error(e);
    await client_1.prisma.$disconnect();
    process.exit(1);
});
//# sourceMappingURL=patch_schema.js.map