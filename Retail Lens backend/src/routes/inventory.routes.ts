import { Router } from 'express';
import { InventoryController } from '../controllers/inventory.controller';

export const inventoryRouter = Router();

inventoryRouter.get('/', InventoryController.getInventory);
inventoryRouter.post('/', InventoryController.createInventory);
inventoryRouter.post('/bulk', InventoryController.bulkCreateOrUpdate);
inventoryRouter.post('/parse-pdf', InventoryController.parsePdf);
inventoryRouter.get('/alerts', InventoryController.getAlerts);
inventoryRouter.patch('/scan-update', InventoryController.scanUpdate);

// Other existing routes (can remain as is or be updated if needed)
inventoryRouter.put('/:id', InventoryController.updateInventory);
inventoryRouter.post('/:id/units', InventoryController.registerUnits);
inventoryRouter.get('/:id/max-serial', InventoryController.getMaxSerial);

inventoryRouter.get('/:id/history', InventoryController.getMovementHistory);
inventoryRouter.get('/:id/fifo-batches', InventoryController.getFIFOBatches);

