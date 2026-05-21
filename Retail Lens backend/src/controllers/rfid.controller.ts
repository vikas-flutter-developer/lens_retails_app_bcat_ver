import { Request, Response } from 'express';
import { prisma } from '../prisma/client';
import { sendSuccess, sendError } from '../utils/response.util';

export class RfidController {
  
  /**
   * 1. BATCH AUDIT: Compares incoming RFID array against DB and detects Missing items.
   */
  static async runBatchAudit(req: Request, res: Response) {
    try {
      const { scannedEpcs } = req.body as { scannedEpcs: string[] };
      
      if (!scannedEpcs || !Array.isArray(scannedEpcs)) {
        return sendError(res, 'scannedEpcs array is required.', 400);
      }

      // Fetch expected SKUs in database (in simplified setup, SKU serves as dummy EPC)
      const allExpected = await prisma.inventoryProduct.findMany({
        select: { sku: true, name: true, stockQuantity: true }
      });

      const expectedSkus = allExpected.map(p => p.sku);
      const foundItems: any[] = [];
      const missingItems: any[] = [];

      const cleanScanned = scannedEpcs.map(e => (e || '').trim().toLowerCase());

      allExpected.forEach(prod => {
        const cleanExpectedSku = (prod.sku || '').trim().toLowerCase();
        if (cleanScanned.includes(cleanExpectedSku)) {
          foundItems.push(prod.name);
        } else {
          missingItems.push(prod.name);
        }
      });

      return sendSuccess(res, {
        totalExpected: expectedSkus.length,
        totalScanned: scannedEpcs.length,
        matchPercent: `${((foundItems.length / expectedSkus.length) * 100).toFixed(1)}%`,
        foundDetails: foundItems,
        missingDetails: missingItems,
      }, 'RFID Audit Cycle Completed.');
    } catch (error: any) {
      return sendError(res, error.message);
    }
  }

  /**
   * 2. SMART CHECKOUT: Converts an array of radio IDs into an instant pending Invoice Object.
   */
  static async smartCheckout(req: Request, res: Response) {
    try {
      const { cartEpcs } = req.body;
      
      if (!cartEpcs || !Array.isArray(cartEpcs)) {
        return sendError(res, 'cartEpcs is required', 400);
      }

      const products = await prisma.inventoryProduct.findMany({
        where: { sku: { in: cartEpcs } }
      });

      const total = products.reduce((sum, p) => sum + (Number(p.salePrice) || 0), 0);

      return sendSuccess(res, {
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
    } catch (error: any) {
      return sendError(res, error.message);
    }
  }

  /**
   * 3. RADAR LOCATE: Verify Item existence and trigger locator metrics
   */
  static async locateItem(req: Request, res: Response) {
    try {
      const epc = req.params.epc as string;
      
      const product = await prisma.inventoryProduct.findUnique({
        where: { sku: epc }
      });

      if (!product) return sendError(res, 'Target not registered in network.', 404);

      return sendSuccess(res, {
        id: product.id,
        name: product.name,
        lastKnownShelf: 'Zone A-Row 3',
        trackingStatus: 'ACTIVE_BEACON',
        frequency: '865.7 MHz'
      }, 'Target Locked for Tracking.');
    } catch (error: any) {
      return sendError(res, error.message);
    }
  }

  /**
   * 4. GATE ALARM: Simulate anti-theft detection
   */
  static async triggerGateAlarm(req: Request, res: Response) {
    try {
      const { epc } = req.body;
      const gateId = req.body.gateId || 'AUTO_DETECTED_GATE';
      
      console.log(`⚠️ SECURITY ALERT: EPC ${epc} detected unauthorized exit at gate: ${gateId}`);
      
      return sendSuccess(res, {
        alarmActive: true,
        timestamp: new Date(),
        action: 'LOCK_FRONT_DOOR',
        detectedAtGate: gateId,
        details: `Tag ${epc} bypassed validation at station ${gateId}.`
      }, 'ALARM DISPATCHED TO SECURITY.');
    } catch (error: any) {
      return sendError(res, error.message);
    }
  }
  /**
   * 5. SHIPMENT VERIFICATION: Checks inward box contents against manifest.
   */
  static async verifyShipment(req: Request, res: Response) {
    try {
      const { shipmentNo, scannedEpcs } = req.body;
      
      if (!shipmentNo || !Array.isArray(scannedEpcs)) {
        return sendError(res, 'shipmentNo and scannedEpcs are required.', 400);
      }

      // In a production app, we look up shipment manifest by shipmentNo in DB.
      // For the simulation, let's set the expected manifest to include our core SKUs.
      const expectedManifest = ['BL-LENS-001', 'PROD-FRAME-001', 'PROD-CL-001', 'PROD-FRAM-101'];
      
      const extraItems = scannedEpcs.filter(x => !expectedManifest.includes(x));
      const missingItems = expectedManifest.filter(x => !scannedEpcs.includes(x));
      const isVerified = missingItems.length === 0 && extraItems.length === 0;

      return sendSuccess(res, {
        shipmentNo,
        verified: isVerified,
        status: isVerified ? 'ACCEPTED' : 'FLAGGED_DISCREPANCY',
        manifestCount: expectedManifest.length,
        actualReceived: scannedEpcs.length,
        missingItems,
        extraUnmanifested: extraItems
      }, isVerified ? 'Shipment Integrity Verified.' : 'Warning: Content Discrepancy Detected.');
    } catch (error: any) {
      return sendError(res, error.message);
    }
  }
}
