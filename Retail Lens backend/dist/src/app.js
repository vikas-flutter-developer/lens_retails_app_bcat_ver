"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.createApp = createApp;
const express_1 = __importDefault(require("express"));
const pino_http_1 = __importDefault(require("pino-http"));
const swagger_ui_express_1 = __importDefault(require("swagger-ui-express"));
const swagger_1 = require("./config/swagger");
const error_handler_1 = require("./middleware/error-handler");
const not_found_1 = require("./middleware/not-found");
const request_id_1 = require("./middleware/request-id");
const routes_1 = require("./routes");
const cors_1 = __importDefault(require("cors"));
function createApp() {
    const app = (0, express_1.default)();
    app.use((0, pino_http_1.default)({ level: process.env.LOG_LEVEL ?? 'info' }));
    app.use(express_1.default.json());
    app.use(request_id_1.requestIdMiddleware);
    app.use((0, cors_1.default)());
    app.use((req, res, next) => {
        try {
            let decodedUrl = decodeURIComponent(req.url);
            let trimmed = decodedUrl.trim();
            if (trimmed.includes('/v1/v1/')) {
                trimmed = trimmed.replace('/v1/v1/', '/v1/');
            }
            if (trimmed !== req.url) {
                req.url = trimmed;
            }
        }
        catch (e) {
        }
        next();
    });
    app.get('/', (req, res) => {
        res.json({
            status: 'ok',
            service: 'retail-lens-api',
            timestamp: new Date().toISOString()
        });
    });
    app.use('/api/docs', swagger_ui_express_1.default.serve, swagger_ui_express_1.default.setup(swagger_1.openApiDocument));
    app.use('/api/v1', routes_1.apiV1Router);
    app.use(not_found_1.notFoundHandler);
    app.use(error_handler_1.errorHandler);
    return app;
}
//# sourceMappingURL=app.js.map