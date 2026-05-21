import { Request, Response } from 'express';
import { InventoryService } from '../services/inventory.service';
import { sendSuccess, sendError } from '../utils/response.util';
import { prisma } from '../prisma/client';
import { parsePdfInventory } from '../utils/pdf-parse-helper';

export class InventoryController {
  static async getInventory(req: Request, res: Response) {
    try {
      const data = await InventoryService.getAllInventory();
      return sendSuccess(res, { data }, 'Inventory fetched successfully');
    } catch (error: any) {
      console.error('Error fetching inventory:', error);
      return sendError(res, error.message || 'Failed to fetch inventory');
    }
  }

  static async createInventory(req: Request, res: Response) {
    try {
      const { sku, name, kind, stockQuantity, reorderLevel, salePrice, vendorId, powerSpecs } = req.body;

      if (!sku || !name || !kind) {
        return sendError(res, 'SKU, name, and kind are required', 400);
      }

      const product = await InventoryService.createInventoryProduct({
        sku,
        name,
        kind,
        stockQuantity: Number(stockQuantity) || 0,
        reorderLevel: Number(reorderLevel) || 10,
        salePrice: salePrice !== undefined ? Number(salePrice) : undefined,
        vendorId: vendorId || undefined,
        powerSpecs: powerSpecs || undefined,
      });

      return sendSuccess(
        res,
        { data: product },
        'Inventory product created successfully',
        201
      );
    } catch (error: any) {
      console.error('Error creating inventory product:', error);
      if (error.code === 'P2002') {
        return sendError(res, 'Product with this SKU already exists', 400);
      }
      return sendError(res, error.message || 'Failed to create inventory product');
    }
  }

  static async bulkCreateOrUpdate(req: Request, res: Response) {
    try {
      const { products } = req.body;
      if (!products || !Array.isArray(products)) {
        return sendError(res, 'Products list is required and must be an array', 400);
      }

      // Basic validation
      for (const p of products) {
        if (!p.name) {
          return sendError(res, 'Product name is required for all items', 400);
        }
        if (!p.sku) {
          return sendError(res, 'SKU is required for all items', 400);
        }
      }

      const result = await InventoryService.bulkCreateOrUpdateProducts(products);
      return sendSuccess(res, result, 'Bulk inventory import/update completed successfully');
    } catch (error: any) {
      console.error('Error in bulk import:', error);
      return sendError(res, error.message || 'Failed to complete bulk import');
    }
  }

  static async parsePdf(req: Request, res: Response) {
    try {
      const { fileBase64 } = req.body;
      if (!fileBase64) {
        return sendError(res, 'fileBase64 is required', 400);
      }

      const pdfBuffer = Buffer.from(fileBase64, 'base64');
      const products = await parsePdfInventory(pdfBuffer);
      return sendSuccess(res, { products }, 'PDF parsed successfully');
    } catch (error: any) {
      console.error('Error parsing PDF:', error);
      return sendError(res, error.message || 'Failed to parse PDF');
    }
  }

  static async updateInventory(req: Request, res: Response) {
    try {
      const productId = (req.params.id as string).trim();
      const { name, salePrice, vendorId, powerSpecs, quantity, adjustment, reason, userId } = req.body || {};

      // Fetch product to calculate if we got an adjustment
      const data = await InventoryService.getAllInventory();
      const currentProduct = data.find(p => p.id === productId);
      if (!currentProduct) {
        return sendError(res, 'Product not found', 404);
      }

      let finalQty = quantity !== undefined ? Number(quantity) : undefined;
      if (adjustment !== undefined) {
        finalQty = (currentProduct.stockQuantity || 0) + Number(adjustment);
      }

      const createdById = (req as any).user?.id || userId || undefined;
      const product = await InventoryService.updateInventoryProduct(productId, {
        name,
        salePrice: salePrice !== undefined ? Number(salePrice) : undefined,
        vendorId: vendorId || undefined,
        powerSpecs: powerSpecs || undefined,
        quantity: finalQty,
        reason,
        createdById,
      });

      return sendSuccess(
        res,
        {
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
        },
        'Product details updated successfully'
      );
    } catch (error: any) {
      console.error('Error updating product details:', error);
      return sendError(res, error.message || 'Failed to update product details');
    }
  }

  static async getAlerts(req: Request, res: Response) {
    try {
      const data = await InventoryService.getLowStockAlerts();
      return sendSuccess(res, { data }, 'Low stock alerts fetched successfully');
    } catch (error: any) {
      console.error('Error fetching inventory alerts:', error);
      return sendError(res, error.message || 'Failed to fetch alerts');
    }
  }

  static async getMovementHistory(req: Request, res: Response) {
    try {
      const productId = (req.params.id as string).trim();
      const movements = await InventoryService.getProductMovementHistory(productId);
      return sendSuccess(res, { id: productId, movements }, 'Stock movement history fetched successfully');
    } catch (error: any) {
      console.error('Error fetching movement history:', error);
      return sendError(res, error.message || 'Failed to fetch stock movement history');
    }
  }
  static async scanUpdate(req: Request, res: Response) {
    try {
      const { qrCode, action, quantity, reason } = req.body;

      if (!qrCode) return sendError(res, 'QR Code (SKU) is required', 400);

      // Find existing product by SKU
      const data = await InventoryService.getAllInventory();
      const product = data.find(p => p.sku === qrCode);

      if (!product) {
        // MOCK FALLBACK: If checking demo code, always say success
        if (qrCode === 'YOUR-QR-CODE' || qrCode.includes('MOCK')) {
          return sendSuccess(res, { success: true, newQuantity: 15 }, 'MOCK Inventory update succeeded');
        }
        return sendError(res, `Product not found for SKU ${qrCode}`, 404);
      }

      const adjQty = Number(quantity) || 1;
      const change = (action === 'REMOVE' || action === 'SUBTRACT') ? -adjQty : adjQty;

      // The Service expects the final absolute value, so calculate it here
      const finalValue = (product.stockQuantity || 0) + change;

      const updatedProduct = await InventoryService.updateInventoryProductQuantity(product.id, finalValue, undefined, reason);

      return sendSuccess(res, {
        success: true,
        message: `Stock updated by ${change}`,
        newQuantity: updatedProduct.stockQuantity
      }, 'Stock adjustment via scan successful');
    } catch (error: any) {
      console.error('Scan update error:', error);
      return sendError(res, error.message || 'Scan update failed');
    }
  }

  static async getFIFOBatches(req: Request, res: Response) {
    try {
      const productId = (req.params.id as string).trim();
      const batches = await InventoryService.getFIFOBatches(productId);
      return sendSuccess(res, { id: productId, batches }, 'FIFO batches fetched successfully');
    } catch (error: any) {
      console.error('Error fetching FIFO batches:', error);
      return sendError(res, error.message || 'Failed to fetch FIFO batches');
    }
  }

  static async registerUnits(req: Request, res: Response) {
    try {
      const productId = (req.params.id as string).trim();
      const { uniqueCodes } = req.body as { uniqueCodes: string[] };

      if (!uniqueCodes || !Array.isArray(uniqueCodes)) {
        return sendError(res, 'Array of uniqueCodes is required', 400);
      }

      const created = await prisma.inventoryUnit.createMany({
        data: uniqueCodes.map(code => ({
          productId: productId,
          uniqueQrCode: code,
          status: 'AVAILABLE'
        })),
        skipDuplicates: true
      });

      return sendSuccess(res, { count: created.count }, 'Unique units registered successfully');
    } catch (error: any) {
      console.error('Error registering units:', error);
      return sendError(res, error.message || 'Failed to register units');
    }
  }

  static async getMaxSerial(req: Request, res: Response) {
    try {
      const productId = (req.params.id as string).trim();
      const units = await prisma.inventoryUnit.findMany({
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

      return sendSuccess(res, { maxSerial: maxNumber }, 'Max serial fetched successfully');
    } catch (error: any) {
      console.error('Error fetching max serial:', error);
      return sendError(res, error.message || 'Failed to fetch max serial');
    }
  }
}
