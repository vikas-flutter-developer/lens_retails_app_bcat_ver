import { ReportsService } from './reports.service';
export declare class ReportsController {
    private readonly reportsService;
    constructor(reportsService: ReportsService);
    getSalesReport(from?: string, to?: string, employeeId?: string): {
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
