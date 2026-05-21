import { prisma } from '../prisma/client';

/**
 * Handles inventory deductions and serial status tracking when a Job Card's status is changed.
 * This is executed when status transitions to DELIVERED.
 */
export async function deductInventoryForJobCard(jobCardId: string, txClient?: any) {
  const client = txClient || prisma;
  
  try {
    // 1. Fetch the JobCard with all its items
    const jobCard = await client.jobCard.findUnique({
      where: { id: jobCardId },
      include: { items: true }
    });
    
    if (!jobCard) {
      console.warn(`[InventorySync] JobCard ${jobCardId} not found for inventory deduction.`);
      return;
    }

    console.log(`[InventorySync] Processing inventory deduction for JobCard ${jobCard.id} (Bill: ${jobCard.billNo})`);

    // 2. Loop through each item in the JobCard
    for (const item of jobCard.items) {
      if (!item.productId) {
        console.log(`[InventorySync] Skipping item ${item.description} (No productId linked).`);
        continue;
      }

      // Check if we already deducted inventory for this item to prevent double deduction
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

      // A. Decrement the main product stock quantity
      const product = await client.inventoryProduct.findUnique({
        where: { id: item.productId }
      });

      if (product) {
        const newQty = Math.max(0, product.stockQuantity - item.quantity);
        await client.inventoryProduct.update({
          where: { id: item.productId },
          data: { stockQuantity: newQty }
        });

        // B. Create a negative inventory movement tracking entry
        await client.inventoryMovement.create({
          data: {
            productId: item.productId,
            quantity: -item.quantity,
            reason: `Deducted for JobCard Delivery (Bill: ${jobCard.billNo || jobCard.id})`
          }
        });
        
        console.log(`[InventorySync] Deducted ${item.quantity} units of product ${product.sku} (${product.name}) from inventory. New stock: ${newQty}`);
      }

      // C. Update specific InventoryUnit records to "SOLD"
      // Attempt to find if the item description matches an InventoryUnit uniqueQrCode
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
        
        // If they bought more than 1 unit, process the remainder under FIFO logic
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
      } else {
        // Fallback: If no direct description match, mark the oldest AVAILABLE units as SOLD under FIFO
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
  } catch (error) {
    console.error('[InventorySync] Error executing deductInventoryForJobCard:', error);
  }
}

/**
 * Handles reversing inventory deductions if a Job Card status is changed BACK from DELIVERED or marked as RETURNED.
 */
export async function restoreInventoryForJobCard(jobCardId: string, isReturn: boolean = false, txClient?: any) {
  const client = txClient || prisma;
  
  try {
    // 1. Fetch the JobCard with all its items
    const jobCard = await client.jobCard.findUnique({
      where: { id: jobCardId },
      include: { items: true }
    });
    
    if (!jobCard) {
      console.warn(`[InventorySync] JobCard ${jobCardId} not found for inventory restoration.`);
      return;
    }

    console.log(`[InventorySync] Reversing inventory deduction for JobCard ${jobCard.id} (Bill: ${jobCard.billNo})`);

    // 2. Loop through each item in the JobCard
    for (const item of jobCard.items) {
      if (!item.productId) continue;

      // Check if there was an inventory deduction movement for this JobCard
      const deductionMovement = await client.inventoryMovement.findFirst({
        where: {
          productId: item.productId,
          reason: `Deducted for JobCard Delivery (Bill: ${jobCard.billNo || jobCard.id})`
        }
      });

      // Avoid double-restoring or double-returning
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

      // A. Increment the main product stock quantity back
      const product = await client.inventoryProduct.findUnique({
        where: { id: item.productId }
      });

      if (product) {
        const newQty = product.stockQuantity + item.quantity;
        await client.inventoryProduct.update({
          where: { id: item.productId },
          data: { stockQuantity: newQty }
        });

        // B. Create a positive movement tracking entry for perfect audit history
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

      // C. Restore matching unique unit records back to "AVAILABLE"
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
  } catch (error) {
    console.error('[InventorySync] Error executing restoreInventoryForJobCard:', error);
  }
}

/**
 * Main coordinator function that monitors a Job Card's status transition and executes sync.
 */
export async function syncInventoryOnStatusChange(jobCardId: string, oldStatus: string, newStatus: string, txClient?: any) {
  if (oldStatus === newStatus) return;

  // Transitioning INTO Delivered
  if (newStatus === 'DELIVERED') {
    await deductInventoryForJobCard(jobCardId, txClient);
  }
  // Transitioning INTO Returned
  else if (newStatus === 'RETURNED') {
    await restoreInventoryForJobCard(jobCardId, true, txClient);
  }
  // Transitioning OUT of Delivered to something else (e.g. DRAFT, CANCELLED)
  else if (oldStatus === 'DELIVERED') {
    await restoreInventoryForJobCard(jobCardId, false, txClient);
  }
  // Transitioning OUT of Returned to DELIVERED (e.g. re-delivered/re-billed)
  else if (oldStatus === 'RETURNED' && newStatus === 'DELIVERED') {
    await deductInventoryForJobCard(jobCardId, txClient);
  }
}
