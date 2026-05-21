"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.vendorsRouter = void 0;
const express_1 = require("express");
const vendors_controller_1 = require("../controllers/vendors.controller");
exports.vendorsRouter = (0, express_1.Router)();
exports.vendorsRouter.get('/', vendors_controller_1.VendorsController.getVendors);
exports.vendorsRouter.get('/:id', vendors_controller_1.VendorsController.getVendorById);
exports.vendorsRouter.get('/:id/ledger', vendors_controller_1.VendorsController.getVendorLedger);
exports.vendorsRouter.post('/', vendors_controller_1.VendorsController.createVendor);
exports.vendorsRouter.delete('/:id', vendors_controller_1.VendorsController.deleteVendor);
exports.vendorsRouter.post('/:id/pay', vendors_controller_1.VendorsController.payVendor);
exports.vendorsRouter.put('/:id', vendors_controller_1.VendorsController.updateVendor);
//# sourceMappingURL=vendors.routes.js.map