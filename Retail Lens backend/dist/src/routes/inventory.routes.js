"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.inventoryRouter = void 0;
const express_1 = require("express");
const inventory_controller_1 = require("../controllers/inventory.controller");
exports.inventoryRouter = (0, express_1.Router)();
exports.inventoryRouter.get('/', inventory_controller_1.InventoryController.getInventory);
exports.inventoryRouter.post('/', inventory_controller_1.InventoryController.createInventory);
exports.inventoryRouter.get('/alerts', inventory_controller_1.InventoryController.getAlerts);
exports.inventoryRouter.patch('/scan-update', inventory_controller_1.InventoryController.scanUpdate);
exports.inventoryRouter.put('/:id', inventory_controller_1.InventoryController.updateInventory);
exports.inventoryRouter.post('/:id/units', inventory_controller_1.InventoryController.registerUnits);
exports.inventoryRouter.get('/:id/max-serial', inventory_controller_1.InventoryController.getMaxSerial);
exports.inventoryRouter.get('/:id/history', inventory_controller_1.InventoryController.getMovementHistory);
exports.inventoryRouter.get('/:id/fifo-batches', inventory_controller_1.InventoryController.getFIFOBatches);
//# sourceMappingURL=inventory.routes.js.map