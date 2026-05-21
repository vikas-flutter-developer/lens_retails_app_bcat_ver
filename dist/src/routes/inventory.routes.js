"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.inventoryRouter = void 0;
const express_1 = require("express");
exports.inventoryRouter = (0, express_1.Router)();
exports.inventoryRouter.post('/', (req, res) => {
    const payload = req.body;
    res.status(201).json({
        id: 'inv_demo',
        sku: payload.sku ?? '',
        name: payload.name ?? '',
        kind: payload.kind ?? 'FRAME',
        stockQuantity: 0,
    });
});
exports.inventoryRouter.get('/', (_req, res) => {
    res.json([]);
});
exports.inventoryRouter.put('/:id', (req, res) => {
    const { quantity } = req.body;
    res.json({
        id: req.params.id,
        stockQuantity: quantity ?? 0,
        updated: true,
    });
});
exports.inventoryRouter.get('/:id/history', (req, res) => {
    res.json({ id: req.params.id, movements: [] });
});
exports.inventoryRouter.get('/alerts', (_req, res) => {
    res.json([]);
});
//# sourceMappingURL=inventory.routes.js.map