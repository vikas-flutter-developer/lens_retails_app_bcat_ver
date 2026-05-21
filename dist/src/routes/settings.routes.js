"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.settingsRouter = void 0;
const express_1 = require("express");
exports.settingsRouter = (0, express_1.Router)();
exports.settingsRouter.get('/store', (_req, res) => {
    res.json({
        storeName: 'Retail Lens',
        gstNumber: null,
        address: null,
    });
});
exports.settingsRouter.put('/store', (req, res) => {
    const payload = req.body;
    res.json({
        storeName: payload.storeName ?? 'Retail Lens',
        gstNumber: payload.gstNumber ?? null,
        address: payload.address ?? null,
        updatedAt: new Date().toISOString(),
    });
});
//# sourceMappingURL=settings.routes.js.map