"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.employeesRouter = void 0;
const express_1 = require("express");
const employees_controller_1 = require("../controllers/employees.controller");
exports.employeesRouter = (0, express_1.Router)();
exports.employeesRouter.get('/', employees_controller_1.EmployeesController.getEmployees);
exports.employeesRouter.get('/all/tasks', employees_controller_1.EmployeesController.getEmployeesForTasks);
exports.employeesRouter.post('/', employees_controller_1.EmployeesController.createEmployee);
exports.employeesRouter.put('/:id', employees_controller_1.EmployeesController.updateEmployee);
exports.employeesRouter.patch('/:id', employees_controller_1.EmployeesController.updateEmployee);
exports.employeesRouter.delete('/:id', employees_controller_1.EmployeesController.deleteEmployee);
exports.employeesRouter.get('/:id/tasks', employees_controller_1.EmployeesController.getEmployeeTaskCounts);
//# sourceMappingURL=employees.routes.js.map