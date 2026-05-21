"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.rfidRouter = void 0;
const express_1 = require("express");
const rfid_controller_1 = require("../controllers/rfid.controller");
exports.rfidRouter = (0, express_1.Router)();
exports.rfidRouter.post('/batch-audit', rfid_controller_1.RfidController.runBatchAudit);
exports.rfidRouter.post('/smart-checkout', rfid_controller_1.RfidController.smartCheckout);
exports.rfidRouter.get('/locate/:epc', rfid_controller_1.RfidController.locateItem);
exports.rfidRouter.post('/security-alarm', rfid_controller_1.RfidController.triggerGateAlarm);
exports.rfidRouter.post('/verify-shipment', rfid_controller_1.RfidController.verifyShipment);
//# sourceMappingURL=rfid.routes.js.map