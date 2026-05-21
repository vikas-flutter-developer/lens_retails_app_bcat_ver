"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ordersRouter = void 0;
const express_1 = require("express");
const orders_controller_1 = require("../controllers/orders.controller");
const client_1 = require("../prisma/client");
exports.ordersRouter = (0, express_1.Router)();
exports.ordersRouter.get('/', orders_controller_1.OrdersController.getOrders);
exports.ordersRouter.post('/', orders_controller_1.OrdersController.createOrder);
exports.ordersRouter.patch('/:id', orders_controller_1.OrdersController.updateOrder);
exports.ordersRouter.post('/:id/payments', async (req, res) => {
    try {
        const { id } = req.params;
        const { amount, paymentType, idempotencyKey, amountCollected, paymentMode } = req.body;
        const finalAmount = amount !== undefined ? amount : amountCollected;
        const finalType = paymentType || paymentMode;
        const jobCard = await client_1.prisma.jobCard.findUnique({
            where: { id },
        });
        if (!jobCard) {
            return res.status(404).json({ error: 'JobCard not found' });
        }
        if (idempotencyKey) {
            const existingPayment = await client_1.prisma.payment.findUnique({
                where: { idempotencyKey },
            });
            if (existingPayment) {
                return res.status(200).json(existingPayment);
            }
        }
        const paymentAmount = finalAmount !== undefined ? Number(finalAmount) : 0;
        const payment = await client_1.prisma.payment.create({
            data: {
                jobCardId: id,
                amount: paymentAmount,
                paymentType: (finalType || 'CASH').toUpperCase(),
                idempotencyKey: idempotencyKey || null,
            },
        });
        const allPayments = await client_1.prisma.payment.findMany({
            where: { jobCardId: id },
        });
        const totalPaid = allPayments.reduce((sum, p) => sum + Number(p.amount), 0);
        const totalAmount = Number(jobCard.totalAmount);
        const dueAmount = Math.max(0, totalAmount - totalPaid);
        await client_1.prisma.jobCard.update({
            where: { id },
            data: {
                paidAmount: totalPaid,
                dueAmount: dueAmount,
            },
        });
        res.status(201).json({
            success: true,
            message: 'Payment recorded successfully',
            data: payment
        });
    }
    catch (error) {
        console.error('Error in POST payments:', error);
        res.status(500).json({ error: error.message || 'Internal server error' });
    }
});
//# sourceMappingURL=orders.routes.js.map