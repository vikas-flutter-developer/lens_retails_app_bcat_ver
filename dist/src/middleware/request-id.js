"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.requestIdMiddleware = requestIdMiddleware;
const node_crypto_1 = require("node:crypto");
function requestIdMiddleware(req, res, next) {
    const requestId = req.headers['x-request-id'] ?? (0, node_crypto_1.randomUUID)();
    req.requestId = requestId;
    req.headers['x-request-id'] = requestId;
    res.setHeader('x-request-id', requestId);
    next();
}
//# sourceMappingURL=request-id.js.map