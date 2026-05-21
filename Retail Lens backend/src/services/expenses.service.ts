import { prisma } from '../prisma/client';

export class ExpensesService {
  static async getAllExpenses() {
    return await prisma.expense.findMany({
      orderBy: {
        expenseDate: 'desc',
      },
    });
  }

  static async createExpense(data: {
    title: string;
    amount: number;
    notes?: string;
    paymentMode?: string;
  }) {
    return await prisma.expense.create({
      data: {
        title: data.title,
        amount: data.amount,
        notes: data.notes,
        paymentMode: data.paymentMode || 'CASH',
        expenseDate: new Date(), // Using current date as expense date
      },
    });
  }

  static async updateExpense(id: string, data: {
    title?: string;
    amount?: number;
    notes?: string;
    paymentMode?: string;
  }) {
    return await prisma.expense.update({
      where: { id },
      data: {
        title: data.title,
        amount: data.amount,
        notes: data.notes,
        paymentMode: data.paymentMode,
      },
    });
  }

  static async deleteExpense(id: string) {
    return await prisma.expense.delete({
      where: { id },
    });
  }
}
