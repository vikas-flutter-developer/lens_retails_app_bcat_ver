export declare class ReportsService {
    getSalesReport(filters: {
        from?: string;
        to?: string;
        employeeId?: string;
    }): {
        filters: {
            from?: string;
            to?: string;
            employeeId?: string;
        };
        bookedOrders: number;
        deliveredOrders: number;
        revenue: number;
    };
}
