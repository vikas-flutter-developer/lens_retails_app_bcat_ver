"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.RfidController = void 0;
const client_1 = require("../prisma/client");
const response_util_1 = require("../utils/response.util");
class RfidController {
    static async runBatchAudit(req, res) {
        try {
            const { scannedEpcs } = req.body;
            if (!scannedEpcs || !Array.isArray(scannedEpcs)) {
                return (0, response_util_1.sendError)(res, 'scannedEpcs array is required.', 400);
            }
            const allExpected = await client_1.prisma.inventoryProduct.findMany({
                select: { sku: true, name: true, stockQuantity: true }
            });
            const expectedSkus = allExpected.map(p => p.sku);
            const foundItems = [];
            const missingItems = [];
            const cleanScanned = scannedEpcs.map(e => (e || '').trim().toLowerCase());
            allExpected.forEach(prod => {
                const cleanExpectedSku = (prod.sku || '').trim().toLowerCase();
                if (cleanScanned.includes(cleanExpectedSku)) {
                    foundItems.push(prod.name);
                }
                else {
                    missingItems.push(prod.name);
                }
            });
            return (0, response_util_1.sendSuccess)(res, {
                totalExpected: expectedSkus.length,
                totalScanned: scannedEpcs.length,
                matchPercent: `${((foundItems.length / expectedSkus.length) * 100).toFixed(1)}%`,
                foundDetails: foundItems,
                missingDetails: missingItems,
            }, 'RFID Audit Cycle Completed.');
        }
        catch (error) {
            return (0, response_util_1.sendError)(res, error.message);
        }
    }
    static async smartCheckout(req, res) {
        try {
            const { cartEpcs } = req.body;
            if (!cartEpcs || !Array.isArray(cartEpcs)) {
                return (0, response_util_1.sendError)(res, 'cartEpcs is required', 400);
            }
            const products = await client_1.prisma.inventoryProduct.findMany({
                where: { sku: { in: cartEpcs } }
            });
            const total = products.reduce((sum, p) => sum + (Number(p.salePrice) || 0), 0);
            return (0, response_util_1.sendSuccess)(res, {
                itemsCount: products.length,
                items: products.map(p => ({
                    id: p.id,
                    name: p.name,
                    price: p.salePrice,
                    powerSpecs: p.powerSpecs
                })),
                subtotal: total,
                tax: total * 0.18,
                grandTotal: total * 1.18,
                paymentLink: 'https://example.com/pay/pending'
            }, 'RFID Cart Pulled Successfully.');
        }
        catch (error) {
            return (0, response_util_1.sendError)(res, error.message);
        }
    }
    static async locateItem(req, res) {
        try {
            const epc = req.params.epc;
            const product = await client_1.prisma.inventoryProduct.findUnique({
                where: { sku: epc }
            });
            if (!product)
                return (0, response_util_1.sendError)(res, 'Target not registered in network.', 404);
            return (0, response_util_1.sendSuccess)(res, {
                id: product.id,
                name: product.name,
                lastKnownShelf: 'Zone A-Row 3',
                trackingStatus: 'ACTIVE_BEACON',
                frequency: '865.7 MHz'
            }, 'Target Locked for Tracking.');
        }
        catch (error) {
            return (0, response_util_1.sendError)(res, error.message);
        }
    }
    static async triggerGateAlarm(req, res) {
        try {
            const { epc } = req.body;
            const gateId = req.body.gateId || 'AUTO_DETECTED_GATE';
            console.log(`⚠️ SECURITY ALERT: EPC ${epc} detected unauthorized exit at gate: ${gateId}`);
            return (0, response_util_1.sendSuccess)(res, {
                alarmActive: true,
                timestamp: new Date(),
                action: 'LOCK_FRONT_DOOR',
                detectedAtGate: gateId,
                details: `Tag ${epc} bypassed validation at station ${gateId}.`
            }, 'ALARM DISPATCHED TO SECURITY.');
        }
        catch (error) {
            return (0, response_util_1.sendError)(res, error.message);
        }
    }
    static async verifyShipment(req, res) {
        try {
            const { shipmentNo, scannedEpcs } = req.body;
            if (!shipmentNo || !Array.isArray(scannedEpcs)) {
                return (0, response_util_1.sendError)(res, 'shipmentNo and scannedEpcs are required.', 400);
            }
            const expectedManifest = ['BL-LENS-001', 'PROD-FRAME-001', 'PROD-CL-001', 'PROD-FRAM-101'];
            const extraItems = scannedEpcs.filter(x => !expectedManifest.includes(x));
            const missingItems = expectedManifest.filter(x => !scannedEpcs.includes(x));
            const isVerified = missingItems.length === 0 && extraItems.length === 0;
            return (0, response_util_1.sendSuccess)(res, {
                shipmentNo,
                verified: isVerified,
                status: isVerified ? 'ACCEPTED' : 'FLAGGED_DISCREPANCY',
                manifestCount: expectedManifest.length,
                actualReceived: scannedEpcs.length,
                missingItems,
                extraUnmanifested: extraItems
            }, isVerified ? 'Shipment Integrity Verified.' : 'Warning: Content Discrepancy Detected.');
        }
        catch (error) {
            return (0, response_util_1.sendError)(res, error.message);
        }
    }
}
exports.RfidController = RfidController;
//# sourceMappingURL=rfid.controller.js.map