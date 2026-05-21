"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.syncRouter = void 0;
const express_1 = require("express");
exports.syncRouter = (0, express_1.Router)();
exports.syncRouter.post('/', (req, res) => {
    const payload = req.body;
    res.status(202).json({
        batchId: 'sync_batch_demo',
        deviceId: payload.deviceId ?? '',
        accepted: payload.actions?.length ?? 0,
        conflicts: [],
        idempotencyKey: payload.idempotencyKey ?? null,
    });
});
//# sourceMappingURL=sync.routes.js.map