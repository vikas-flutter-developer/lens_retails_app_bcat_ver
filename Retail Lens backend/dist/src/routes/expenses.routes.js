"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.expensesRouter = void 0;
const express_1 = require("express");
const expenses_controller_1 = require("../controllers/expenses.controller");
exports.expensesRouter = (0, express_1.Router)();
exports.expensesRouter.get('/', expenses_controller_1.ExpensesController.getExpenses);
exports.expensesRouter.post('/', expenses_controller_1.ExpensesController.createExpense);
exports.expensesRouter.put('/:id', expenses_controller_1.ExpensesController.updateExpense);
exports.expensesRouter.delete('/:id', expenses_controller_1.ExpensesController.deleteExpense);
//# sourceMappingURL=expenses.routes.js.map