"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.authRouter = void 0;
const express_1 = require("express");
const auth_controller_1 = require("../controllers/auth.controller");
const payment_controller_1 = require("../controllers/payment.controller");
const payment_routes_1 = require("./payment.routes");
exports.authRouter = (0, express_1.Router)();
exports.authRouter.post('/register', auth_controller_1.AuthController.register);
exports.authRouter.post('/login', auth_controller_1.AuthController.login);
exports.authRouter.get('/owners', payment_controller_1.PaymentController.getAllOwners);
exports.authRouter.use('/payment', payment_routes_1.paymentRouter);
exports.authRouter.post('/refresh', auth_controller_1.AuthController.refresh);
exports.authRouter.post('/logout', auth_controller_1.AuthController.logout);
exports.authRouter.post('/forgot-password', auth_controller_1.AuthController.forgotPassword);
exports.authRouter.post('/reset-password', auth_controller_1.AuthController.resetPassword);
//# sourceMappingURL=auth.routes.js.map