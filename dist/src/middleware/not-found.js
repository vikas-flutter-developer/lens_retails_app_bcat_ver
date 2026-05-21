"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.notFoundHandler = notFoundHandler;
function notFoundHandler(req, res) {
    res.status(404).json({
        statusCode: 404,
        path: req.originalUrl,
        method: req.method,
        timestamp: new Date().toISOString(),
        requestId: req.requestId ?? null,
        error: {
            message: 'Route not found',
        },
    });
}
//# sourceMappingURL=not-found.js.map