export declare class OrdersService {
    static getAllOrders(): Promise<{
        id: string;
        sn: string;
        billNo: string;
        date: string;
        customer: string;
        mobile: string;
        orderStatus: import("@prisma/client").$Enums.JobCardStatus;
        amount: number;
        paidAmount: number;
        dueAmount: number;
        orderType: string;
        title: string;
        priority: string;
        notes: string;
        expectedCompletionDate: string | null;
        items: {
            description: string;
            sph: string;
            cyl: string;
            axis: string;
            add: string;
            eye: string;
            quantity: number;
            unitPrice: number;
            lineTotal: number;
        }[];
    }[]>;
    static createOrder(data: any): Promise<{
        customer: {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            email: string | null;
            fullName: string;
            address: string | null;
            phone: string;
            dob: string | null;
        };
        items: {
            id: string;
            createdAt: Date;
            productId: string | null;
            quantity: number;
            description: string;
            unitPrice: import("@prisma/client/runtime/library").Decimal;
            lineTotal: import("@prisma/client/runtime/library").Decimal;
            sph: string | null;
            cyl: string | null;
            axis: string | null;
            add: string | null;
            eye: string | null;
            jobCardId: string;
        }[];
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        status: import("@prisma/client").$Enums.JobCardStatus;
        customerId: string;
        totalAmount: import("@prisma/client/runtime/library").Decimal;
        paidAmount: import("@prisma/client/runtime/library").Decimal;
        dueAmount: import("@prisma/client/runtime/library").Decimal;
        billNo: string | null;
        billSeries: string | null;
        orderType: string | null;
        bookedBy: string | null;
        godown: string | null;
        title: string | null;
        priority: string | null;
        notes: string | null;
        expectedCompletionDate: Date | null;
    }>;
    static updateOrder(id: string, data: any): Promise<{
        customer: {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            email: string | null;
            fullName: string;
            address: string | null;
            phone: string;
            dob: string | null;
        };
        items: {
            id: string;
            createdAt: Date;
            productId: string | null;
            quantity: number;
            description: string;
            unitPrice: import("@prisma/client/runtime/library").Decimal;
            lineTotal: import("@prisma/client/runtime/library").Decimal;
            sph: string | null;
            cyl: string | null;
            axis: string | null;
            add: string | null;
            eye: string | null;
            jobCardId: string;
        }[];
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        status: import("@prisma/client").$Enums.JobCardStatus;
        customerId: string;
        totalAmount: import("@prisma/client/runtime/library").Decimal;
        paidAmount: import("@prisma/client/runtime/library").Decimal;
        dueAmount: import("@prisma/client/runtime/library").Decimal;
        billNo: string | null;
        billSeries: string | null;
        orderType: string | null;
        bookedBy: string | null;
        godown: string | null;
        title: string | null;
        priority: string | null;
        notes: string | null;
        expectedCompletionDate: Date | null;
    }>;
}
