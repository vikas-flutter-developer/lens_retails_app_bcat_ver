"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.notificationsRouter = void 0;
const express_1 = require("express");
exports.notificationsRouter = (0, express_1.Router)();
exports.notificationsRouter.post('/send', (req, res) => {
    const payload = req.body;
    res.status(202).json({
        id: 'notification_demo',
        status: 'queued',
        channel: payload.channel ?? 'WHATSAPP',
        recipient: payload.recipient ?? '',
        message: payload.message ?? '',
        queuedAt: new Date().toISOString(),
    });
});
//# sourceMappingURL=notifications.routes.js.map