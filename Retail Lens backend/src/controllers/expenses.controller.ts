import { Request, Response } from 'express';
import { ExpensesService } from '../services/expenses.service';
import { sendSuccess, sendError } from '../utils/response.util';

export class ExpensesController {
  private static formatDate(date: Date): string {
    const d = new Date(date);
    const day = String(d.getDate()).padStart(2, '0');
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const year = d.getFullYear();
    return `${day}-${month}-${year}`;
  }

  static async getExpenses(req: Request, res: Response) {
    try {
      const expenses = await ExpensesService.getAllExpenses();
      
      const data = expenses.map(exp => ({
        id: exp.id,
        title: exp.title,
        amount: Number(exp.amount),
        notes: exp.notes,
        paymentMode: (exp as any).paymentMode || 'CASH',
        date: ExpensesController.formatDate(exp.expenseDate)
      }));

      return sendSuccess(res, { data }, 'Expenses fetched successfully');
    } catch (error: any) {
      console.error('Error fetching expenses:', error);
      return sendError(res, error.message || 'Failed to fetch expenses');
    }
  }

  static async createExpense(req: Request, res: Response) {
    try {
      const { title, amount, notes, paymentMode } = req.body;

      if (!title || amount === undefined) {
        return sendError(res, 'Title and amount are required', 400);
      }

      const expense = await ExpensesService.createExpense({
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
        paymentMode: (expense as any).paymentMode || 'CASH',
        date: ExpensesController.formatDate(expense.expenseDate)
      };

      return sendSuccess(res, { data }, 'Expense created successfully', 201);
    } catch (error: any) {
      console.error('Error creating expense:', error);
      return sendError(res, error.message || 'Failed to create expense');
    }
  }

  static async updateExpense(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const { title, amount, notes, paymentMode } = req.body;

      const expense = await ExpensesService.updateExpense(id as string, {
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
        paymentMode: (expense as any).paymentMode || 'CASH',
        date: ExpensesController.formatDate(expense.expenseDate)
      };

      return sendSuccess(res, { data }, 'Expense updated successfully');
    } catch (error: any) {
      console.error('Error updating expense:', error);
      return sendError(res, error.message || 'Failed to update expense');
    }
  }

  static async deleteExpense(req: Request, res: Response) {
    try {
      const { id } = req.params;
      await ExpensesService.deleteExpense(id as string);
      return sendSuccess(res, null, 'Expense deleted successfully');
    } catch (error: any) {
      console.error('Error deleting expense:', error);
      return sendError(res, error.message || 'Failed to delete expense');
    }
  }
}
