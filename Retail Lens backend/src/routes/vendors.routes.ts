import { Router } from 'express';
import { VendorsController } from '../controllers/vendors.controller';

export const vendorsRouter = Router();

vendorsRouter.get('/', VendorsController.getVendors);
vendorsRouter.get('/:id', VendorsController.getVendorById);
vendorsRouter.get('/:id/ledger', VendorsController.getVendorLedger);
vendorsRouter.post('/', VendorsController.createVendor);
vendorsRouter.delete('/:id', VendorsController.deleteVendor);
vendorsRouter.post('/:id/pay', VendorsController.payVendor);
vendorsRouter.put('/:id', VendorsController.updateVendor);
