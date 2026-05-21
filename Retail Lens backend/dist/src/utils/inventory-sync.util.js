"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deductInventoryForJobCard = deductInventoryForJobCard;
exports.restoreInventoryForJobCard = restoreInventoryForJobCard;
exports.syncInventoryOnStatusChange = syncInventoryOnStatusChange;
const client_1 = require("../prisma/client");
async function deductInventoryForJobCard(jobCardId, txClient) {
    const client = txClient || client_1.prisma;
    try {
        const jobCard = await client.jobCard.findUnique({
            where: { id: jobCardId },
            include: { items: true }
        });
        if (!jobCard) {
            console.warn(`[InventorySync] JobCard ${jobCardId} not found for inventory deduction.`);
            return;
        }
        console.log(`[InventorySync] Processing inventory deduction for JobCard ${jobCard.id} (Bill: ${jobCard.billNo})`);
        for (const item of jobCard.items) {
            if (!item.productId) {
                console.log(`[InventorySync] Skipping item ${item.description} (No productId linked).`);
                continue;
            }
            const existingMovement = await client.inventoryMovement.findFirst({
                where: {
                    productId: item.productId,
                    reason: {
                        startsWith: `Deducted for JobCard Delivery (Bill: ${jobCard.billNo || jobCard.id})`
                    }
                }
            });
            if (existingMovement) {
                console.log(`[InventorySync] Inventory already deducted for item ${item.id} in JobCard ${jobCard.id}. Skipping.`);
                continue;
            }
            const product = await client.inventoryProduct.findUnique({
                where: { id: item.productId }
            });
            if (product) {
                const newQty = Math.max(0, product.stockQuantity - item.quantity);
                await client.inventoryProduct.update({
                    where: { id: item.productId },
                    data: { stockQuantity: newQty }
                });
                await client.inventoryMovement.create({
                    data: {
                        productId: item.productId,
                        quantity: -item.quantity,
                        reason: `Deducted for JobCard Delivery (Bill: ${jobCard.billNo || jobCard.id})`
                    }
                });
                console.log(`[InventorySync] Deducted ${item.quantity} units of product ${product.sku} (${product.name}) from inventory. New stock: ${newQty}`);
            }
            let matchedUnit = await client.inventoryUnit.findFirst({
                where: {
                    productId: item.productId,
                    uniqueQrCode: item.description,
                    status: 'AVAILABLE'
                }
            });
            if (matchedUnit) {
                await client.inventoryUnit.update({
                    where: { id: matchedUnit.id },
                    data: { status: 'SOLD' }
                });
                console.log(`[InventorySync] Marked matched unique unit ${matchedUnit.uniqueQrCode} as SOLD directly.`);
                if (item.quantity > 1) {
                    const oldestAvailable = await client.inventoryUnit.findMany({
                        where: {
                            productId: item.productId,
                            status: 'AVAILABLE',
                            id: { not: matchedUnit.id }
                        },
                        orderBy: { createdAt: 'asc' },
                        take: item.quantity - 1
                    });
                    for (const unit of oldestAvailable) {
                        await client.inventoryUnit.update({
                            where: { id: unit.id },
                            data: { status: 'SOLD' }
                        });
                        console.log(`[InventorySync] Marked additional unique unit ${unit.uniqueQrCode} as SOLD under FIFO.`);
                    }
                }
            }
            else {
                const oldestAvailable = await client.inventoryUnit.findMany({
                    where: {
                        productId: item.productId,
                        status: 'AVAILABLE'
                    },
                    orderBy: { createdAt: 'asc' },
                    take: item.quantity
                });
                for (const unit of oldestAvailable) {
                    await client.inventoryUnit.update({
                        where: { id: unit.id },
                        data: { status: 'SOLD' }
                    });
                    console.log(`[InventorySync] Marked unique unit ${unit.uniqueQrCode} as SOLD under FIFO.`);
                }
            }
        }
    }
    catch (error) {
        console.error('[InventorySync] Error executing deductInventoryForJobCard:', error);
    }
}
async function restoreInventoryForJobCard(jobCardId, isReturn = false, txClient) {
    const client = txClient || client_1.prisma;
    try {
        const jobCard = await client.jobCard.findUnique({
            where: { id: jobCardId },
            include: { items: true }
        });
        if (!jobCard) {
            console.warn(`[InventorySync] JobCard ${jobCardId} not found for inventory restoration.`);
            return;
        }
        console.log(`[InventorySync] Reversing inventory deduction for JobCard ${jobCard.id} (Bill: ${jobCard.billNo})`);
        for (const item of jobCard.items) {
            if (!item.productId)
                continue;
            const deductionMovement = await client.inventoryMovement.findFirst({
                where: {
                    productId: item.productId,
                    reason: `Deducted for JobCard Delivery (Bill: ${jobCard.billNo || jobCard.id})`
                }
            });
            const alreadyRestored = await client.inventoryMovement.findFirst({
                where: {
                    productId: item.productId,
                    reason: {
                        in: [
                            `Returned by Customer (Bill: ${jobCard.billNo || jobCard.id})`,
                            `Restored / Returned for JobCard (Bill: ${jobCard.billNo || jobCard.id})`
                        ]
                    }
                }
            });
            if (!deductionMovement) {
                console.log(`[InventorySync] No prior deduction movement found for product ${item.productId} in JobCard ${jobCard.id}. Skipping.`);
                continue;
            }
            if (alreadyRestored) {
                console.log(`[InventorySync] Already restored / returned for product ${item.productId} in JobCard ${jobCard.id}. Skipping.`);
                continue;
            }
            const product = await client.inventoryProduct.findUnique({
                where: { id: item.productId }
            });
            if (product) {
                const newQty = product.stockQuantity + item.quantity;
                await client.inventoryProduct.update({
                    where: { id: item.productId },
                    data: { stockQuantity: newQty }
                });
                const reason = isReturn
                    ? `Returned by Customer (Bill: ${jobCard.billNo || jobCard.id})`
                    : `Restored / Returned for JobCard (Bill: ${jobCard.billNo || jobCard.id})`;
                await client.inventoryMovement.create({
                    data: {
                        productId: item.productId,
                        quantity: item.quantity,
                        reason: reason
                    }
                });
                console.log(`[InventorySync] Restored ${item.quantity} units of product ${product.sku} (${product.name}) back to inventory. New stock: ${newQty}`);
            }
            const soldUnits = await client.inventoryUnit.findMany({
                where: {
                    productId: item.productId,
                    status: 'SOLD'
                },
                orderBy: { updatedAt: 'desc' },
                take: item.quantity
            });
            for (const unit of soldUnits) {
                await client.inventoryUnit.update({
                    where: { id: unit.id },
                    data: { status: 'AVAILABLE' }
                });
                console.log(`[InventorySync] Restored unique unit ${unit.uniqueQrCode} back to AVAILABLE.`);
            }
        }
    }
    catch (error) {
        console.error('[InventorySync] Error executing restoreInventoryForJobCard:', error);
    }
}
async function syncInventoryOnStatusChange(jobCardId, oldStatus, newStatus, txClient) {
    if (oldStatus === newStatus)
        return;
    if (newStatus === 'DELIVERED') {
        await deductInventoryForJobCard(jobCardId, txClient);
    }
    else if (newStatus === 'RETURNED') {
        await restoreInventoryForJobCard(jobCardId, true, txClient);
    }
    else if (oldStatus === 'DELIVERED') {
        await restoreInventoryForJobCard(jobCardId, false, txClient);
    }
    else if (oldStatus === 'RETURNED' && newStatus === 'DELIVERED') {
        await deductInventoryForJobCard(jobCardId, txClient);
    }
}
//# sourceMappingURL=inventory-sync.util.js.map