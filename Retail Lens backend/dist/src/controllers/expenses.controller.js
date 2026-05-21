"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ExpensesController = void 0;
const expenses_service_1 = require("../services/expenses.service");
const response_util_1 = require("../utils/response.util");
class ExpensesController {
    static formatDate(date) {
        const d = new Date(date);
        const day = String(d.getDate()).padStart(2, '0');
        const month = String(d.getMonth() + 1).padStart(2, '0');
        const year = d.getFullYear();
        return `${day}-${month}-${year}`;
    }
    static async getExpenses(req, res) {
        try {
            const expenses = await expenses_service_1.ExpensesService.getAllExpenses();
            const data = expenses.map(exp => ({
                id: exp.id,
                title: exp.title,
                amount: Number(exp.amount),
                notes: exp.notes,
                paymentMode: exp.paymentMode || 'CASH',
                date: ExpensesController.formatDate(exp.expenseDate)
            }));
            return (0, response_util_1.sendSuccess)(res, { data }, 'Expenses fetched successfully');
        }
        catch (error) {
            console.error('Error fetching expenses:', error);
            return (0, response_util_1.sendError)(res, error.message || 'Failed to fetch expenses');
        }
    }
    static async createExpense(req, res) {
        try {
            const { title, amount, notes, paymentMode } = req.body;
            if (!title || amount === undefined) {
                return (0, response_util_1.sendError)(res, 'Title and amount are required', 400);
            }
            const expense = await expenses_service_1.ExpensesService.createExpense({
                title,
                amount: Number(amount),
                notes,
                paymentMode
            });
            const data = {
                id: expense.id,
                title: expense.title,
                amount: Number(expense.amount),
                notes: expense.notes,
                paymentMode: expense.paymentMode || 'CASH',
                date: ExpensesController.formatDate(expense.expenseDate)
            };
            return (0, response_util_1.sendSuccess)(res, { data }, 'Expense created successfully', 201);
        }
        catch (error) {
            console.error('Error creating expense:', error);
            return (0, response_util_1.sendError)(res, error.message || 'Failed to create expense');
        }
    }
    static async updateExpense(req, res) {
        try {
            const { id } = req.params;
            const { title, amount, notes, paymentMode } = req.body;
            const expense = await expenses_service_1.ExpensesService.updateExpense(id, {
                title,
                amount: amount !== undefined ? Number(amount) : undefined,
                notes,
                paymentMode
            });
            const data = {
                id: expense.id,
                title: expense.title,
                amount: Number(expense.amount),
                notes: expense.notes,
                paymentMode: expense.paymentMode || 'CASH',
                date: ExpensesController.formatDate(expense.expenseDate)
            };
            return (0, response_util_1.sendSuccess)(res, { data }, 'Expense updated successfully');
        }
        catch (error) {
            console.error('Error updating expense:', error);
            return (0, response_util_1.sendError)(res, error.message || 'Failed to update expense');
        }
    }
    static async deleteExpense(req, res) {
        try {
            const { id } = req.params;
            await expenses_service_1.ExpensesService.deleteExpense(id);
            return (0, response_util_1.sendSuccess)(res, null, 'Expense deleted successfully');
        }
        catch (error) {
            console.error('Error deleting expense:', error);
            return (0, response_util_1.sendError)(res, error.message || 'Failed to delete expense');
        }
    }
}
exports.ExpensesController = ExpensesController;
//# sourceMappingURL=expenses.controller.js.map