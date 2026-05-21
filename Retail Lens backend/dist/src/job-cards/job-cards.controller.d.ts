import { JobCardsService } from './job-cards.service';
export declare class JobCardsController {
    private readonly jobCardsService;
    constructor(jobCardsService: JobCardsService);
    create(body: {
        customerId: string;
    }): {
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
    removeItem(id: string, itemId: string): {
        jobCardId: string;
        itemId: string;
        removed: boolean;
    };
    addPayment(id: string, body: {
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
