"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.paymentRouter = void 0;
const express_1 = require("express");
const payment_controller_1 = require("../controllers/payment.controller");
exports.paymentRouter = (0, express_1.Router)();
exports.paymentRouter.post('/create-order', payment_controller_1.PaymentController.createOrder);
exports.paymentRouter.post('/verify-register', payment_controller_1.PaymentController.verifyPaymentAndRegister);
//# sourceMappingURL=payment.routes.js.map