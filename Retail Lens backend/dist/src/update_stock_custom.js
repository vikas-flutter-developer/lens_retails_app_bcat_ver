"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("./prisma/client");
async function main() {
    const sku = 'PROD-LENS-001';
    console.log(`Locating product with SKU: ${sku}`);
    const product = await client_1.prisma.inventoryProduct.findUnique({
        where: { sku }
    });
    if (!product) {
        console.error('Product not found! Please create the product via the app first.');
        return;
    }
    console.log(`Found product: ${product.name} (ID: ${product.id}). Proceeding with override.`);
    const deleteResult = await client_1.prisma.inventoryMovement.deleteMany({
        where: { productId: product.id }
    });
    console.log(`Deleted ${deleteResult.count} previous stock movements.`);
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
    const today = new Date();
    await client_1.prisma.inventoryMovement.create({
        data: {
            productId: product.id,
            quantity: 50,
            reason: 'Old Stock Entry',
            createdAt: sixMonthsAgo
        }
    });
    console.log('Created batch of 50 units timestamped 6 months ago.');
    await client_1.prisma.inventoryMovement.create({
        data: {
            productId: product.id,
            quantity: 100,
            reason: 'New Received Stock',
            createdAt: today
        }
    });
    console.log('Created batch of 100 units timestamped today.');
    await client_1.prisma.inventoryProduct.update({
        where: { id: product.id },
        data: { stockQuantity: 150 }
    });
    console.log('Updated total product stock counter to 150.');
    console.log('SUCCESS: Inventory distributed as requested.');
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
//# sourceMappingURL=update_stock_custom.js.map