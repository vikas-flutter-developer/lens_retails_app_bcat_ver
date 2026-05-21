"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MobileAnalyticsService = void 0;
const client_1 = require("../prisma/client");
const client_2 = require("@prisma/client");
class MobileAnalyticsService {
    static async getDashboardData() {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const [todayCollectionResult, totalCollectionResult, totalExpenseResult, activeJobCardsCount, pendingTasksCount,] = await Promise.all([
            client_1.prisma.payment.aggregate({
                _sum: {
                    amount: true,
                },
                where: {
                    createdAt: {
                        gte: today,
                    },
                },
            }),
            client_1.prisma.payment.aggregate({
                _sum: {
                    amount: true,
                },
            }),
            client_1.prisma.expense.aggregate({
                _sum: {
                    amount: true,
                },
            }),
            client_1.prisma.jobCard.count({
                where: {
                    status: {
                        in: [client_2.JobCardStatus.DRAFT, client_2.JobCardStatus.IN_PROGRESS, client_2.JobCardStatus.READY],
                    },
                },
            }),
            client_1.prisma.task.count({
                where: {
                    status: {
                        in: [client_2.TaskStatus.PENDING, client_2.TaskStatus.IN_PROGRESS],
                    },
                },
            }),
        ]);
        const lowStockResult = await client_1.prisma.$queryRaw `
      SELECT COUNT(*)::bigint FROM "InventoryProduct" WHERE "stockQuantity" < "reorderLevel"
    `;
        const lowStockCount = Number(lowStockResult[0].count || 0);
        const todayCollection = Number(todayCollectionResult._sum.amount || 0);
        const totalCollections = Number(totalCollectionResult._sum.amount || 0);
        const totalExpenses = Number(totalExpenseResult._sum.amount || 0);
        const cashInHand = totalCollections - totalExpenses;
        const products = await client_1.prisma.inventoryProduct.findMany({
            select: {
                id: true,
                salePrice: true,
                powerSpecs: true,
            },
        });
        const purchasePriceMap = new Map();
        for (const p of products) {
            let pPrice = 0;
            if (p.powerSpecs) {
                const specs = typeof p.powerSpecs === 'string' ? JSON.parse(p.powerSpecs) : p.powerSpecs;
                pPrice = Number(specs.purchasePrice || 0);
            }
            if (!pPrice && p.salePrice) {
                pPrice = p.salePrice * 0.5;
            }
            purchasePriceMap.set(p.id, pPrice);
        }
        const todayItems = await client_1.prisma.jobCardItem.findMany({
            where: {
                createdAt: {
                    gte: today,
                },
            },
        });
        const allItems = await client_1.prisma.jobCardItem.findMany();
        let todayRevenue = 0;
        let todayCost = 0;
        for (const item of todayItems) {
            todayRevenue += Number(item.lineTotal || 0);
            const pPrice = item.productId
                ? (purchasePriceMap.get(item.productId) ?? (Number(item.unitPrice || 0) * 0.5))
                : (Number(item.unitPrice || 0) * 0.5);
            todayCost += pPrice * item.quantity;
        }
        const todayProfit = Math.max(0, todayRevenue - todayCost);
        let netRevenue = 0;
        let netCost = 0;
        for (const item of allItems) {
            netRevenue += Number(item.lineTotal || 0);
            const pPrice = item.productId
                ? (purchasePriceMap.get(item.productId) ?? (Number(item.unitPrice || 0) * 0.5))
                : (Number(item.unitPrice || 0) * 0.5);
            netCost += pPrice * item.quantity;
        }
        const netProfit = Math.max(0, netRevenue - netCost - totalExpenses);
        return {
            todayCollection,
            cashInHand,
            todayProfit,
            netProfit,
            activeJobCards: activeJobCardsCount,
            pendingTasks: pendingTasksCount,
            lowStockCount: lowStockCount,
        };
    }
}
exports.MobileAnalyticsService = MobileAnalyticsService;
//# sourceMappingURL=mobile-analytics.service.js.map