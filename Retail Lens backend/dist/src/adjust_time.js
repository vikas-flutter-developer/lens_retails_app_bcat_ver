"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("./prisma/client");
async function main() {
    console.log('Adjusting recent inventory movement date back by 1 day...');
    const sku = 'PROD-LENS-001';
    const product = await client_1.prisma.inventoryProduct.findUnique({ where: { sku } });
    if (!product) {
        console.error('Product not found!');
        return;
    }
    const latest = await client_1.prisma.inventoryMovement.findFirst({
        where: { productId: product.id, quantity: 100 },
        orderBy: { createdAt: 'desc' }
    });
    if (!latest) {
        console.error('Target movement of +100 not found.');
        return;
    }
    const yesterday = new Date(latest.createdAt);
    yesterday.setDate(yesterday.getDate() - 1);
    await client_1.prisma.inventoryMovement.update({
        where: { id: latest.id },
        data: { createdAt: yesterday }
    });
    console.log(`SUCCESS: Updated date from ${latest.createdAt.toISOString()} to ${yesterday.toISOString()}`);
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
//# sourceMappingURL=adjust_time.js.map