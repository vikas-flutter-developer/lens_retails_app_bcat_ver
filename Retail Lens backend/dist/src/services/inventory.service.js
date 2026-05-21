"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.InventoryService = void 0;
const client_1 = require("../prisma/client");
class InventoryService {
    static async getAllInventory() {
        const products = await client_1.prisma.inventoryProduct.findMany({
            orderBy: { name: 'asc' },
        });
        return products.map((p) => ({
            id: p.id,
            sku: p.sku,
            name: p.name,
            kind: p.kind,
            stockQuantity: p.stockQuantity,
            reorderLevel: p.reorderLevel,
            vendorId: p.vendorId,
            salePrice: p.salePrice,
            powerSpecs: p.powerSpecs,
        }));
    }
    static async createInventoryProduct(data) {
        return await client_1.prisma.$transaction(async (tx) => {
            const product = await tx.inventoryProduct.create({
                data: {
                    sku: data.sku,
                    name: data.name,
                    kind: data.kind,
                    stockQuantity: data.stockQuantity,
                    reorderLevel: data.reorderLevel,
                    salePrice: data.salePrice !== undefined ? data.salePrice : 1200.0,
                    vendorId: data.vendorId || null,
                    powerSpecs: data.powerSpecs || null,
                },
            });
            if (data.stockQuantity > 0) {
                await tx.inventoryMovement.create({
                    data: {
                        productId: product.id,
                        quantity: data.stockQuantity,
                        reason: 'Initial stock on creation',
                    },
                });
            }
            return {
                id: product.id,
                sku: product.sku,
                name: product.name,
                kind: product.kind,
                stockQuantity: product.stockQuantity,
                reorderLevel: product.reorderLevel,
                vendorId: product.vendorId,
                salePrice: product.salePrice,
                powerSpecs: product.powerSpecs,
            };
        });
    }
    static async getLowStockAlerts() {
        const products = await client_1.prisma.inventoryProduct.findMany({
            where: {
                stockQuantity: {
                    lte: client_1.prisma.inventoryProduct.fields.reorderLevel,
                },
            },
        });
        const allProducts = await client_1.prisma.inventoryProduct.findMany();
        const alertProducts = allProducts.filter(p => p.stockQuantity <= p.reorderLevel);
        return alertProducts.map((p) => ({
            id: p.id,
            sku: p.sku,
            name: p.name,
            kind: p.kind,
            stockQuantity: p.stockQuantity,
            reorderLevel: p.reorderLevel,
        }));
    }
    static async getProductMovementHistory(productId) {
        return await client_1.prisma.inventoryMovement.findMany({
            where: { productId },
            orderBy: { createdAt: 'desc' },
        });
    }
    static async updateInventoryProductQuantity(id, quantity, createdById, reason) {
        return this.updateInventoryProduct(id, { quantity, createdById, reason });
    }
    static async updateInventoryProduct(id, data) {
        const productId = id.trim();
        const product = await client_1.prisma.inventoryProduct.findUnique({
            where: { id: productId },
        });
        if (!product) {
            throw new Error('Product not found');
        }
        return await client_1.prisma.$transaction(async (tx) => {
            const updateData = {};
            if (data.name !== undefined)
                updateData.name = data.name;
            if (data.salePrice !== undefined)
                updateData.salePrice = data.salePrice;
            if (data.vendorId !== undefined)
                updateData.vendorId = data.vendorId || null;
            if (data.powerSpecs !== undefined)
                updateData.powerSpecs = data.powerSpecs;
            if (data.quantity !== undefined)
                updateData.stockQuantity = data.quantity;
            const updatedProduct = await tx.inventoryProduct.update({
                where: { id: productId },
                data: updateData,
            });
            if (data.quantity !== undefined) {
                const difference = data.quantity - product.stockQuantity;
                if (difference !== 0) {
                    await tx.inventoryMovement.create({
                        data: {
                            productId,
                            quantity: difference,
                            reason: data.reason || `Manual stock adjustment to ${data.quantity}`,
                            createdById: data.createdById || null,
                        },
                    });
                }
            }
            return updatedProduct;
        });
    }
    static async getFIFOBatches(productId) {
        const movements = await client_1.prisma.inventoryMovement.findMany({
            where: { productId: productId.trim() },
            orderBy: { createdAt: 'asc' },
        });
        const batches = [];
        for (const mov of movements) {
            if (mov.quantity > 0) {
                const match = mov.reason.match(/\[Batch:\s*([a-zA-Z0-9_-]+)\]/i);
                let addedToExisting = false;
                if (match) {
                    const targetBatchId = match[1];
                    const targetBatch = batches.find(b => b.id === targetBatchId);
                    if (targetBatch) {
                        targetBatch.remainingQuantity += mov.quantity;
                        targetBatch.originalQuantity += mov.quantity;
                        addedToExisting = true;
                    }
                }
                if (!addedToExisting) {
                    batches.push({
                        id: mov.id,
                        createdAt: mov.createdAt,
                        originalQuantity: mov.quantity,
                        remainingQuantity: mov.quantity,
                        reason: mov.reason,
                    });
                }
            }
            else if (mov.quantity < 0) {
                let deficit = Math.abs(mov.quantity);
                const match = mov.reason.match(/\[Batch:\s*([a-zA-Z0-9_-]+)\]/i);
                if (match) {
                    const targetBatchId = match[1];
                    const targetBatch = batches.find(b => b.id === targetBatchId);
                    if (targetBatch && targetBatch.remainingQuantity > 0) {
                        const deduction = Math.min(targetBatch.remainingQuantity, deficit);
                        targetBatch.remainingQuantity -= deduction;
                        deficit -= deduction;
                    }
                }
                if (deficit > 0) {
                    for (let i = 0; i < batches.length && deficit > 0; i++) {
                        if (batches[i].remainingQuantity > 0) {
                            const deduction = Math.min(batches[i].remainingQuantity, deficit);
                            batches[i].remainingQuantity -= deduction;
                            deficit -= deduction;
                        }
                    }
                }
            }
        }
        return batches.filter((b) => b.remainingQuantity > 0);
    }
}
exports.InventoryService = InventoryService;
//# sourceMappingURL=inventory.service.js.map