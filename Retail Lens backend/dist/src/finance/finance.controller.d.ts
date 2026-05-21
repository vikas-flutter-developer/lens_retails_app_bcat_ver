import { FinanceService } from './finance.service';
export declare class FinanceController {
    private readonly financeService;
    constructor(financeService: FinanceService);
    getDailySummary(): {
        cashInHand: number;
        salesToday: number;
        deliveriesToday: number;
        framesSoldToday: number;
    };
    createExpense(body: {
        title: string;
        amount: number;
        notes?: string;
    }): {
        createdAt: string;
        title: string;
        amount: number;
        notes?: string;
        id: string;
    };
    updateExpense(id: string, body: {
        title?: string;
        amount?: number;
        notes?: string;
    }): {
        updatedAt: string;
        title?: string;
        amount?: number;
        notes?: string;
        id: string;
    };
    deleteExpense(id: string): {
        id: string;
        deleted: boolean;
    };
}
