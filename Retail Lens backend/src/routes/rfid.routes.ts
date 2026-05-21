import { Router } from 'express';
import { RfidController } from '../controllers/rfid.controller';

export const rfidRouter = Router();

rfidRouter.post('/batch-audit', RfidController.runBatchAudit);
rfidRouter.post('/smart-checkout', RfidController.smartCheckout);
rfidRouter.get('/locate/:epc', RfidController.locateItem);
rfidRouter.post('/security-alarm', RfidController.triggerGateAlarm);
rfidRouter.post('/verify-shipment', RfidController.verifyShipment);
