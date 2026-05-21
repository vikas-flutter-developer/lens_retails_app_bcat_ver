import { Router } from 'express';
import { ExpensesController } from '../controllers/expenses.controller';

export const expensesRouter = Router();

expensesRouter.get('/', ExpensesController.getExpenses);
expensesRouter.post('/', ExpensesController.createExpense);
expensesRouter.put('/:id', ExpensesController.updateExpense);
expensesRouter.delete('/:id', ExpensesController.deleteExpense);
