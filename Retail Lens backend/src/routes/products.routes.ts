import { Router } from 'express';
import { ProductsController } from '../controllers/products.controller';

export const productsRouter = Router();

productsRouter.get('/qr/:qrCode', ProductsController.getProductByQr);
