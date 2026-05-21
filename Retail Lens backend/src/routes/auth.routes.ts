import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller';
import { PaymentController } from '../controllers/payment.controller';
import { paymentRouter } from './payment.routes';

export const authRouter = Router();

// Registration
authRouter.post('/register', AuthController.register);

// Login
authRouter.post('/login', AuthController.login);

// Get all owners and their subscription statuses
authRouter.get('/owners', PaymentController.getAllOwners);

// Mount payment router under auth path to support Postman organization
authRouter.use('/payment', paymentRouter);

// Refresh Token
authRouter.post('/refresh', AuthController.refresh);

// Logout
authRouter.post('/logout', AuthController.logout);

// Forgot Password
authRouter.post('/forgot-password', AuthController.forgotPassword);

// Reset Password
authRouter.post('/reset-password', AuthController.resetPassword);

