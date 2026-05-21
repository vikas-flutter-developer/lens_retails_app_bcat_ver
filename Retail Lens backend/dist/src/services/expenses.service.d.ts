export declare class ExpensesService {
    static getAllExpenses(): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        title: string;
        notes: string | null;
        amount: import("@prisma/client/runtime/library").Decimal;
        paymentMode: string;
        expenseDate: Date;
    }[]>;
    static createExpense(data: {
        title: string;
        amount: number;
        notes?: string;
        paymentMode?: string;
    }): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        title: string;
        notes: string | null;
        amount: import("@prisma/client/runtime/library").Decimal;
        paymentMode: string;
        expenseDate: Date;
    }>;
    static updateExpense(id: string, data: {
        title?: string;
        amount?: number;
        notes?: string;
        paymentMode?: string;
    }): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        title: string;
        notes: string | null;
        amount: import("@prisma/client/runtime/library").Decimal;
        paymentMode: string;
        expenseDate: Date;
    }>;
    static deleteExpense(id: string): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        title: string;
        notes: string | null;
        amount: import("@prisma/client/runtime/library").Decimal;
        paymentMode: string;
        expenseDate: Date;
    }>;
}
