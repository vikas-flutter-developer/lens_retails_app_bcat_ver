"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MobileAnalyticsController = void 0;
const mobile_analytics_service_1 = require("../services/mobile-analytics.service");
const response_util_1 = require("../utils/response.util");
class MobileAnalyticsController {
    static async getDashboard(req, res) {
        try {
            const data = await mobile_analytics_service_1.MobileAnalyticsService.getDashboardData();
            return (0, response_util_1.sendSuccess)(res, { data }, 'Dashboard data fetched successfully');
        }
        catch (error) {
            console.error('Error fetching dashboard analytics:', error);
            return (0, response_util_1.sendError)(res, error.message || 'Failed to fetch dashboard data');
        }
    }
}
exports.MobileAnalyticsController = MobileAnalyticsController;
//# sourceMappingURL=mobile-analytics.controller.js.map