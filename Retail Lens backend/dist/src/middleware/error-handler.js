"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.errorHandler = errorHandler;
function errorHandler(err, req, res, _next) {
    const isError = err instanceof Error;
    res.status(500).json({
        statusCode: 500,
        path: req.originalUrl,
        method: req.method,
        timestamp: new Date().toISOString(),
        requestId: req.requestId ?? null,
        error: {
            message: isError ? err.message : 'Internal server error',
        },
    });
}
//# sourceMappingURL=error-handler.js.map