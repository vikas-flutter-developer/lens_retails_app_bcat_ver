import { Request, Response } from 'express';
export declare class ExpensesController {
    private static formatDate;
    static getExpenses(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static createExpense(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static updateExpense(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static deleteExpense(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
}
