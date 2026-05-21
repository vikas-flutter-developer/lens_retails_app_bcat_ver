"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.mobileAnalyticsRouter = void 0;
const express_1 = require("express");
const mobile_analytics_controller_1 = require("../controllers/mobile-analytics.controller");
exports.mobileAnalyticsRouter = (0, express_1.Router)();
exports.mobileAnalyticsRouter.get('/analytics/dashboard', mobile_analytics_controller_1.MobileAnalyticsController.getDashboard);
//# sourceMappingURL=mobile-analytics.routes.js.map