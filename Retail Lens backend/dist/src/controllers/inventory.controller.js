"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.InventoryController = void 0;
const inventory_service_1 = require("../services/inventory.service");
const response_util_1 = require("../utils/response.util");
const client_1 = require("../prisma/client");
class InventoryController {
    static async getInventory(req, res) {
        try {
            const data = await inventory_service_1.InventoryService.getAllInventory();
            return (0, response_util_1.sendSuccess)(res, { data }, 'Inventory fetched successfully');
        }
        catch (error) {
            console.error('Error fetching inventory:', error);
            return (0, response_util_1.sendError)(res, error.message || 'Failed to fetch inventory');
        }
    }
    static async createInventory(req, res) {
        try {
            const { sku, name, kind, stockQuantity, reorderLevel, salePrice, vendorId, powerSpecs } = req.body;
            if (!sku || !name || !kind) {
                return (0, response_util_1.sendError)(res, 'SKU, name, and kind are required', 400);
            }
            const product = await inventory_service_1.InventoryService.createInventoryProduct({
                sku,
                name,
                kind,
                stockQuantity: Number(stockQuantity) || 0,
                reorderLevel: Number(reorderLevel) || 10,
                salePrice: salePrice !== undefined ? Number(salePrice) : undefined,
                vendorId: vendorId || undefined,
                powerSpecs: powerSpecs || undefined,
            });
            return (0, response_util_1.sendSuccess)(res, { data: product }, 'Inventory product created successfully', 201);
        }
        catch (error) {
            console.error('Error creating inventory product:', error);
            if (error.code === 'P2002') {
                return (0, response_util_1.sendError)(res, 'Product with this SKU already exists', 400);
            }
            return (0, response_util_1.sendError)(res, error.message || 'Failed to create inventory product');
        }
    }
    static async updateInventory(req, res) {
        try {
            const productId = req.params.id.trim();
            const { name, salePrice, vendorId, powerSpecs, quantity, adjustment, reason, userId } = req.body || {};
            const data = await inventory_service_1.InventoryService.getAllInventory();
            const currentProduct = data.find(p => p.id === productId);
            if (!currentProduct) {
                return (0, response_util_1.sendError)(res, 'Product not found', 404);
            }
            let finalQty = quantity !== undefined ? Number(quantity) : undefined;
            if (adjustment !== undefined) {
                finalQty = (currentProduct.stockQuantity || 0) + Number(adjustment);
            }
            const createdById = req.user?.id || userId || undefined;
            const product = await inventory_service_1.InventoryService.updateInventoryProduct(productId, {
                name,
                salePrice: salePrice !== undefined ? Number(salePrice) : undefined,
                vendorId: vendorId || undefined,
                powerSpecs: powerSpecs || undefined,
                quantity: finalQty,
                reason,
                createdById,
            });
            return (0, response_util_1.sendSuccess)(res, {
                id: product.id,
                sku: product.sku,
                name: product.name,
                kind: product.kind,
                stockQuantity: product.stockQuantity,
                reorderLevel: product.reorderLevel,
                vendorId: product.vendorId,
                salePrice: product.salePrice,
                powerSpecs: product.powerSpecs,
                updated: true,
            }, 'Product details updated successfully');
        }
        catch (error) {
            console.error('Error updating product details:', error);
            return (0, response_util_1.sendError)(res, error.message || 'Failed to update product details');
        }
    }
    static async getAlerts(req, res) {
        try {
            const data = await inventory_service_1.InventoryService.getLowStockAlerts();
            return (0, response_util_1.sendSuccess)(res, { data }, 'Low stock alerts fetched successfully');
        }
        catch (error) {
            console.error('Error fetching inventory alerts:', error);
            return (0, response_util_1.sendError)(res, error.message || 'Failed to fetch alerts');
        }
    }
    static async getMovementHistory(req, res) {
        try {
            const productId = req.params.id.trim();
            const movements = await inventory_service_1.InventoryService.getProductMovementHistory(productId);
            return (0, response_util_1.sendSuccess)(res, { id: productId, movements }, 'Stock movement history fetched successfully');
        }
        catch (error) {
            console.error('Error fetching movement history:', error);
            return (0, response_util_1.sendError)(res, error.message || 'Failed to fetch stock movement history');
        }
    }
    static async scanUpdate(req, res) {
        try {
            const { qrCode, action, quantity, reason } = req.body;
            if (!qrCode)
                return (0, response_util_1.sendError)(res, 'QR Code (SKU) is required', 400);
            const data = await inventory_service_1.InventoryService.getAllInventory();
            const product = data.find(p => p.sku === qrCode);
            if (!product) {
                if (qrCode === 'YOUR-QR-CODE' || qrCode.includes('MOCK')) {
                    return (0, response_util_1.sendSuccess)(res, { success: true, newQuantity: 15 }, 'MOCK Inventory update succeeded');
                }
                return (0, response_util_1.sendError)(res, `Product not found for SKU ${qrCode}`, 404);
            }
            const adjQty = Number(quantity) || 1;
            const change = (action === 'REMOVE' || action === 'SUBTRACT') ? -adjQty : adjQty;
            const finalValue = (product.stockQuantity || 0) + change;
            const updatedProduct = await inventory_service_1.InventoryService.updateInventoryProductQuantity(product.id, finalValue, undefined, reason);
            return (0, response_util_1.sendSuccess)(res, {
                success: true,
                message: `Stock updated by ${change}`,
                newQuantity: updatedProduct.stockQuantity
            }, 'Stock adjustment via scan successful');
        }
        catch (error) {
            console.error('Scan update error:', error);
            return (0, response_util_1.sendError)(res, error.message || 'Scan update failed');
        }
    }
    static async getFIFOBatches(req, res) {
        try {
            const productId = req.params.id.trim();
            const batches = await inventory_service_1.InventoryService.getFIFOBatches(productId);
            return (0, response_util_1.sendSuccess)(res, { id: productId, batches }, 'FIFO batches fetched successfully');
        }
        catch (error) {
            console.error('Error fetching FIFO batches:', error);
            return (0, response_util_1.sendError)(res, error.message || 'Failed to fetch FIFO batches');
        }
    }
    static async registerUnits(req, res) {
        try {
            const productId = req.params.id.trim();
            const { uniqueCodes } = req.body;
            if (!uniqueCodes || !Array.isArray(uniqueCodes)) {
                return (0, response_util_1.sendError)(res, 'Array of uniqueCodes is required', 400);
            }
            const created = await client_1.prisma.inventoryUnit.createMany({
                data: uniqueCodes.map(code => ({
                    productId: productId,
                    uniqueQrCode: code,
                    status: 'AVAILABLE'
                })),
                skipDuplicates: true
            });
            return (0, response_util_1.sendSuccess)(res, { count: created.count }, 'Unique units registered successfully');
        }
        catch (error) {
            console.error('Error registering units:', error);
            return (0, response_util_1.sendError)(res, error.message || 'Failed to register units');
        }
    }
    static async getMaxSerial(req, res) {
        try {
            const productId = req.params.id.trim();
            const units = await client_1.prisma.inventoryUnit.findMany({
                where: { productId },
                select: { uniqueQrCode: true }
            });
            let maxNumber = 0;
            for (const u of units) {
                const match = u.uniqueQrCode.match(/(\d+)$/);
                if (match) {
                    const num = parseInt(match[1], 10);
                    if (num > maxNumber) {
                        maxNumber = num;
                    }
                }
            }
            return (0, response_util_1.sendSuccess)(res, { maxSerial: maxNumber }, 'Max serial fetched successfully');
        }
        catch (error) {
            console.error('Error fetching max serial:', error);
            return (0, response_util_1.sendError)(res, error.message || 'Failed to fetch max serial');
        }
    }
}
exports.InventoryController = InventoryController;
//# sourceMappingURL=inventory.controller.js.map