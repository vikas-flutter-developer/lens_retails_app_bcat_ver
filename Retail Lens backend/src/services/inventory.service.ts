import { prisma } from '../prisma/client';
import { InventoryKind } from '@prisma/client';

export interface StockBatch {
  id: string;
  createdAt: Date;
  originalQuantity: number;
  remainingQuantity: number;
  reason: string;
}

export class InventoryService {
  static async getAllInventory() {
    const products = await prisma.inventoryProduct.findMany({
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

  static async createInventoryProduct(data: {
    sku: string;
    name: string;
    kind: InventoryKind;
    stockQuantity: number;
    reorderLevel: number;
    salePrice?: number;
    vendorId?: string;
    powerSpecs?: any;
  }) {
    return await prisma.$transaction(async (tx) => {
      // 1. Create the product
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

      // 2. Create an initial movement if quantity > 0
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

  static async bulkCreateOrUpdateProducts(
    products: Array<{
      sku: string;
      name: string;
      kind: InventoryKind;
      stockQuantity: number;
      salePrice?: number;
      purchasePrice?: number;
    }>
  ) {
    return await prisma.$transaction(async (tx) => {
      let createdCount = 0;
      let updatedCount = 0;

      for (const p of products) {
        const sku = p.sku.trim();
        const existing = await tx.inventoryProduct.findUnique({
          where: { sku },
        });

        const stockQuantity = Number(p.stockQuantity) || 0;
        const salePrice = p.salePrice !== undefined ? Number(p.salePrice) : 1200.0;
        const purchasePrice = p.purchasePrice !== undefined ? Number(p.purchasePrice) : 0.0;

        if (existing) {
          // Update existing product
          const updated = await tx.inventoryProduct.update({
            where: { id: existing.id },
            data: {
              name: p.name,
              kind: p.kind,
              stockQuantity: stockQuantity, // Overwrite with current sheet stock
              salePrice: salePrice,
              powerSpecs: {
                ...(existing.powerSpecs as object || {}),
                purchasePrice: purchasePrice,
              },
            },
          });

          // Log movement for the change
          const diff = stockQuantity - existing.stockQuantity;
          if (diff !== 0) {
            await tx.inventoryMovement.create({
              data: {
                productId: existing.id,
                quantity: diff,
                reason: `Bulk Excel import adjustment (stock reset from ${existing.stockQuantity} to ${stockQuantity})`,
              },
            });
          }
          updatedCount++;
        } else {
          // Create new product
          const newProduct = await tx.inventoryProduct.create({
            data: {
              sku,
              name: p.name,
              kind: p.kind,
              stockQuantity: stockQuantity,
              reorderLevel: 10,
              salePrice: salePrice,
              powerSpecs: {
                purchasePrice: purchasePrice,
              },
            },
          });

          if (stockQuantity > 0) {
            await tx.inventoryMovement.create({
              data: {
                productId: newProduct.id,
                quantity: stockQuantity,
                reason: 'Initial stock on Excel import creation',
              },
            });
          }
          createdCount++;
        }
      }

      return { createdCount, updatedCount };
    });
  }

  static async getLowStockAlerts() {
    const products = await prisma.inventoryProduct.findMany({
      where: {
        stockQuantity: {
          lte: prisma.inventoryProduct.fields.reorderLevel,
        },
      },
      // Unfortunately Prisma doesn't support column-to-column comparison directly in where easily
      // for some versions/databases without raw or computed fields.
      // Let's check if we can do it via a more compatible way if needed.
    });

    // Wait, Prisma 'where' with fields comparison is tricky.
    // Let's use findMany and filter for now if the dataset is small, 
    // or use a raw query if it's large.
    // Actually, Prisma does NOT support where field comparison natively in a simple way.
    
    // Alternative: fetch all and filter in JS for now, as requested "optimize" but "keep it simple".
    // Or better, use a filter in JS for safety across DB providers.
    
    const allProducts = await prisma.inventoryProduct.findMany();
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

  static async getProductMovementHistory(productId: string) {
    return await prisma.inventoryMovement.findMany({
      where: { productId },
      orderBy: { createdAt: 'desc' },
    });
  }

  static async updateInventoryProductQuantity(id: string, quantity: number, createdById?: string, reason?: string) {
    return this.updateInventoryProduct(id, { quantity, createdById, reason });
  }

  static async updateInventoryProduct(
    id: string,
    data: {
      name?: string;
      salePrice?: number;
      vendorId?: string | null;
      powerSpecs?: any;
      quantity?: number;
      reason?: string;
      createdById?: string;
    }
  ) {
    const productId = id.trim();
    const product = await prisma.inventoryProduct.findUnique({
      where: { id: productId },
    });

    if (!product) {
      throw new Error('Product not found');
    }

    return await prisma.$transaction(async (tx) => {
      const updateData: any = {};
      if (data.name !== undefined) updateData.name = data.name;
      if (data.salePrice !== undefined) updateData.salePrice = data.salePrice;
      if (data.vendorId !== undefined) updateData.vendorId = data.vendorId || null;
      if (data.powerSpecs !== undefined) updateData.powerSpecs = data.powerSpecs;
      if (data.quantity !== undefined) updateData.stockQuantity = data.quantity;

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

  static async getFIFOBatches(productId: string) {
    const movements = await prisma.inventoryMovement.findMany({
      where: { productId: productId.trim() },
      orderBy: { createdAt: 'asc' },
    });

    const batches: StockBatch[] = [];

    for (const mov of movements) {
      if (mov.quantity > 0) {
        // Try to target a specific batch if the reason includes [Batch: <id>]
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
      } else if (mov.quantity < 0) {
        let deficit = Math.abs(mov.quantity);
        
        // 1. Try to target a specific batch if the reason includes [Batch: <id>]
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
        
        // 2. Fallback to standard FIFO for any remaining deficit
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
