export declare class JobCardsService {
    create(customerId: string): {
        id: string;
        customerId: string;
        status: string;
        createdAt: string;
    };
    findOne(id: string): {
        id: string;
        status: string;
        items: never[];
        payments: never[];
    };
    removeItem(jobCardId: string, itemId: string): {
        jobCardId: string;
        itemId: string;
        removed: boolean;
    };
    addPayment(jobCardId: string, payment: {
        amount: number;
        paymentType: string;
        idempotencyKey?: string;
    }): {
        recordedAt: string;
        amount: number;
        paymentType: string;
        idempotencyKey?: string;
        id: string;
        jobCardId: string;
    };
}
