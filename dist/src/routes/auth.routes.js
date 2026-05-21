"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.authRouter = void 0;
const express_1 = require("express");
exports.authRouter = (0, express_1.Router)();
exports.authRouter.post('/login', (req, res) => {
    const { email } = req.body;
    res.json({
        user: { id: 'demo-user', email: email ?? '', role: 'OWNER' },
        accessToken: 'replace-with-jwt-token',
        refreshToken: 'replace-with-refresh-token',
    });
});
exports.authRouter.post('/refresh', (_req, res) => {
    res.json({ accessToken: 'replace-with-jwt-token' });
});
//# sourceMappingURL=auth.routes.js.map