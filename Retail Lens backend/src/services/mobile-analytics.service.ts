import { prisma } from '../prisma/client';
import { JobCardStatus, TaskStatus } from '@prisma/client';

export class MobileAnalyticsService {
  static async getDashboardData() {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [
      todayCollectionResult,
      totalCollectionResult,
      totalExpenseResult,
      activeJobCardsCount,
      pendingTasksCount,
    ] = await Promise.all([
      // todayCollection: Total amount collected today
      prisma.payment.aggregate({
        _sum: {
          amount: true,
        },
        where: {
          createdAt: {
            gte: today,
          },
        },
      }),

      // For cashInHand: total collections - expenses
      prisma.payment.aggregate({
        _sum: {
          amount: true,
        },
      }),

      prisma.expense.aggregate({
        _sum: {
          amount: true,
        },
      }),

      // activeJobCards: Count of active/open/in-progress job cards
      prisma.jobCard.count({
        where: {
          status: {
            in: [JobCardStatus.DRAFT, JobCardStatus.IN_PROGRESS, JobCardStatus.READY],
          },
        },
      }),

      // pendingTasks: Count of pending tasks
      prisma.task.count({
        where: {
          status: {
            in: [TaskStatus.PENDING, TaskStatus.IN_PROGRESS],
          },
        },
      }),
    ]);

    // lowStockCount: Count of items with stockQuantity < reorderLevel
    // Using raw query as Prisma doesn't support direct field comparison in where clause easily
    const lowStockResult = await prisma.$queryRaw<[{ count: bigint }]>`
      SELECT COUNT(*)::bigint FROM "InventoryProduct" WHERE "stockQuantity" < "reorderLevel"
    `;
    const lowStockCount = Number(lowStockResult[0].count || 0);

    const todayCollection = Number(todayCollectionResult._sum.amount || 0);
    const totalCollections = Number(totalCollectionResult._sum.amount || 0);
    const totalExpenses = Number(totalExpenseResult._sum.amount || 0);
    const cashInHand = totalCollections - totalExpenses;

    // --- PROFIT CALCULATIONS ---
    const products = await prisma.inventoryProduct.findMany({
      select: {
        id: true,
        salePrice: true,
        powerSpecs: true,
      },
    });

    const purchasePriceMap = new Map<string, number>();
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

    const todayItems = await prisma.jobCardItem.findMany({
      where: {
        createdAt: {
          gte: today,
        },
      },
    });

    const allItems = await prisma.jobCardItem.findMany();

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
