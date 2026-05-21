"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.financeRouter = void 0;
const express_1 = require("express");
exports.financeRouter = (0, express_1.Router)();
exports.financeRouter.get('/daily-summary', (_req, res) => {
    res.json({
        cashInHand: 0,
        salesToday: 0,
        deliveriesToday: 0,
        framesSoldToday: 0,
    });
});
exports.financeRouter.post('/expenses', (req, res) => {
    const payload = req.body;
    res.status(201).json({
        id: 'expense_demo',
        title: payload.title ?? '',
        amount: payload.amount ?? 0,
        notes: payload.notes ?? null,
        createdAt: new Date().toISOString(),
    });
});
exports.financeRouter.put('/expenses/:id', (req, res) => {
    const payload = req.body;
    res.json({
        id: req.params.id,
        ...payload,
        updatedAt: new Date().toISOString(),
    });
});
exports.financeRouter.delete('/expenses/:id', (req, res) => {
    res.json({ id: req.params.id, deleted: true });
});
//# sourceMappingURL=finance.routes.js.map