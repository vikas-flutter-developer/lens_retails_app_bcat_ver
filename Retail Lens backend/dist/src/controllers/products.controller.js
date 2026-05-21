"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ProductsController = void 0;
const client_1 = require("../prisma/client");
const response_util_1 = require("../utils/response.util");
class ProductsController {
    static async getProductByQr(req, res) {
        try {
            const qrCode = req.params.qrCode;
            const unit = await client_1.prisma.inventoryUnit.findUnique({
                where: { uniqueQrCode: qrCode },
                include: {
                    product: {
                        include: { vendor: true }
                    }
                }
            });
            if (unit) {
                const product = unit.product;
                const allAvailable = await client_1.prisma.inventoryUnit.findMany({
                    where: {
                        productId: product.id,
                        status: 'AVAILABLE'
                    },
                    orderBy: { createdAt: 'asc' },
                    take: 1
                });
                const oldestUnit = allAvailable[0];
                const isOldest = !oldestUnit || oldestUnit.id === unit.id;
                return (0, response_util_1.sendSuccess)(res, {
                    data: {
                        ...product,
                        isSerialized: true,
                        unitId: unit.id,
                        status: unit.status,
                        isOldestAvailable: isOldest,
                        suggestedQrCode: isOldest ? null : oldestUnit.uniqueQrCode
                    }
                }, 'Serialized Item Verified successfully');
            }
            const product = await client_1.prisma.inventoryProduct.findUnique({
                where: { sku: qrCode },
                include: { vendor: true }
            });
            if (!product) {
                if (qrCode === 'YOUR-QR-CODE' || qrCode === 'PROD-MOCK-1') {
                    return (0, response_util_1.sendSuccess)(res, {
                        data: {
                            id: "prod-xyz123-mock",
                            sku: qrCode,
                            name: "Sample Mock Frame",
                            kind: "FRAME",
                            stockQuantity: 10,
                            salePrice: 2500,
                            vendor: "Sample Vendor Lab"
                        }
                    }, 'MOCK Product returned successfully');
                }
                return (0, response_util_1.sendError)(res, `Product with code ${qrCode} not found`, 404);
            }
            return (0, response_util_1.sendSuccess)(res, { data: product }, 'Product retrieved via QR successfully');
        }
        catch (error) {
            console.error('Error scanning QR:', error);
            return (0, response_util_1.sendError)(res, error.message || 'Failed to retrieve product');
        }
    }
}
exports.ProductsController = ProductsController;
//# sourceMappingURL=products.controller.js.map