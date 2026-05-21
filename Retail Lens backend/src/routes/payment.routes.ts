import { Router } from 'express';
import { PaymentController } from '../controllers/payment.controller';

export const paymentRouter = Router();

// Create Razorpay order
paymentRouter.post('/create-order', PaymentController.createOrder);

// Verify payment and register user
paymentRouter.post('/verify-register', PaymentController.verifyPaymentAndRegister);
