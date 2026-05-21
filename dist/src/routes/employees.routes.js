"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.employeesRouter = void 0;
const express_1 = require("express");
exports.employeesRouter = (0, express_1.Router)();
exports.employeesRouter.get('/:id/tasks', (req, res) => {
    res.json({
        employeeId: req.params.id,
        assigned: 0,
        completed: 0,
        pending: 0,
    });
});
//# sourceMappingURL=employees.routes.js.map