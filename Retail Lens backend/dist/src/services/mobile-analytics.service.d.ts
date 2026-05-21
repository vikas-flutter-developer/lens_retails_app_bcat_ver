export declare class MobileAnalyticsService {
    static getDashboardData(): Promise<{
        todayCollection: number;
        cashInHand: number;
        todayProfit: number;
        netProfit: number;
        activeJobCards: number;
        pendingTasks: number;
        lowStockCount: number;
    }>;
}
