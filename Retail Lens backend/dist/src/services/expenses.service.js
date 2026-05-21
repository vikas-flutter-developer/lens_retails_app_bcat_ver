"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ExpensesService = void 0;
const client_1 = require("../prisma/client");
class ExpensesService {
    static async getAllExpenses() {
        return await client_1.prisma.expense.findMany({
            orderBy: {
                expenseDate: 'desc',
            },
        });
    }
    static async createExpense(data) {
        return await client_1.prisma.expense.create({
            data: {
                title: data.title,
                amount: data.amount,
                notes: data.notes,
                paymentMode: data.paymentMode || 'CASH',
                expenseDate: new Date(),
            },
        });
    }
    static async updateExpense(id, data) {
        return await client_1.prisma.expense.update({
            where: { id },
            data: {
                title: data.title,
                amount: data.amount,
                notes: data.notes,
                paymentMode: data.paymentMode,
            },
        });
    }
    static async deleteExpense(id) {
        return await client_1.prisma.expense.delete({
            where: { id },
        });
    }
}
exports.ExpensesService = ExpensesService;
//# sourceMappingURL=expenses.service.js.map