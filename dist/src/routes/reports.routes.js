"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.reportsRouter = void 0;
const express_1 = require("express");
exports.reportsRouter = (0, express_1.Router)();
exports.reportsRouter.get('/sales', (req, res) => {
    const { from, to, employeeId } = req.query;
    res.json({
        filters: {
            from: typeof from === 'string' ? from : undefined,
            to: typeof to === 'string' ? to : undefined,
            employeeId: typeof employeeId === 'string' ? employeeId : undefined,
        },
        bookedOrders: 0,
        deliveredOrders: 0,
        revenue: 0,
    });
});
//# sourceMappingURL=reports.routes.js.map