"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.jobCardsRouter = void 0;
const express_1 = require("express");
exports.jobCardsRouter = (0, express_1.Router)();
exports.jobCardsRouter.post('/', (req, res) => {
    const { customerId } = req.body;
    res.status(201).json({
        id: 'jc_demo',
        customerId: customerId ?? null,
        status: 'DRAFT',
        createdAt: new Date().toISOString(),
    });
});
exports.jobCardsRouter.get('/:id', (req, res) => {
    res.json({
        id: req.params.id,
        status: 'DRAFT',
        items: [],
        payments: [],
    });
});
exports.jobCardsRouter.delete('/:id/items/:itemId', (req, res) => {
    res.json({
        jobCardId: req.params.id,
        itemId: req.params.itemId,
        removed: true,
    });
});
exports.jobCardsRouter.post('/:id/payments', (req, res) => {
    const payload = req.body;
    res.status(201).json({
        id: 'payment_demo',
        jobCardId: req.params.id,
        amount: payload.amount ?? 0,
        paymentType: payload.paymentType ?? 'CASH',
        idempotencyKey: payload.idempotencyKey ?? null,
        recordedAt: new Date().toISOString(),
    });
});
//# sourceMappingURL=job-cards.routes.js.map