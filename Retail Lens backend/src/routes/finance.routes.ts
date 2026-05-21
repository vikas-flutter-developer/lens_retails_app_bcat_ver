import { Router } from 'express';
import { prisma } from '../prisma/client';
import { sendSuccess, sendError } from '../utils/response.util';

export const financeRouter = Router();

financeRouter.get('/daily-summary', async (req, res) => {
  try {
    const { date, isMonthly } = req.query; // format: 'YYYY-MM-DD'
    const targetDate = date ? new Date(date as string) : new Date();
    
    const startOfDay = new Date(targetDate);
    if (isMonthly === 'true') {
      startOfDay.setDate(1);
    }
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date(targetDate);
    endOfDay.setHours(23, 59, 59, 999);

    // 1. Fetch Payments received today
    const payments = await prisma.payment.findMany({
      where: {
        createdAt: {
          gte: startOfDay,
          lte: endOfDay
        }
      }
    });

    const cashReceived = payments
      .filter(p => p.paymentType === 'CASH')
      .reduce((sum, p) => sum + Number(p.amount), 0);

    const upiReceived = payments
      .filter(p => p.paymentType === 'UPI')
      .reduce((sum, p) => sum + Number(p.amount), 0);

    const cardReceived = payments
      .filter(p => p.paymentType === 'CARD' || p.paymentType === 'BANK_TRANSFER')
      .reduce((sum, p) => sum + Number(p.amount), 0);

    const totalCashReceived = cashReceived;
    const totalNonCashReceived = upiReceived + cardReceived;
    const totalCollections = totalCashReceived + totalNonCashReceived;

    // 2. Fetch Expenses paid today
    const expenses = await prisma.expense.findMany({
      where: {
        expenseDate: {
          gte: startOfDay,
          lte: endOfDay
        }
      }
    });
    const totalExpensesPaid = expenses.reduce((sum, e) => sum + Number(e.amount), 0);

    // 3. Fetch Sales (Sell) today from JobCard
    const sales = await prisma.jobCard.findMany({
      where: {
        createdAt: {
          gte: startOfDay,
          lte: endOfDay
        }
      }
    });
    const totalSalesToday = sales.reduce((sum, j) => sum + Number(j.totalAmount), 0);

    // 4. Calculate Dynamic Purchases today based on actual sold items
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

    const jobCardItems = await prisma.jobCardItem.findMany({
      where: {
        createdAt: {
          gte: startOfDay,
          lte: endOfDay,
        },
      },
    });

    let totalPurchaseToday = 0;
    for (const item of jobCardItems) {
      const pPrice = item.productId 
        ? (purchasePriceMap.get(item.productId) ?? (Number(item.unitPrice || 0) * 0.5)) 
        : (Number(item.unitPrice || 0) * 0.5);
      totalPurchaseToday += pPrice * item.quantity;
    }

    const totalProfitToday = Math.max(0, totalSalesToday - totalPurchaseToday - totalExpensesPaid);

    // Map response following our client structures perfectly
    const financeData = {
      totalCashReceived,
      totalNonCashReceived,
      totalCollections,
      totalExpensesPaid,
      totalSalesToday,
      totalPurchaseToday,
      totalProfitToday,
      cashInHand: totalCashReceived - totalExpensesPaid,
      cashReceived,
      upiReceived,
      cardReceived,
    };

    return sendSuccess(res, { data: financeData }, 'Daily finance summary fetched successfully');
  } catch (error: any) {
    console.error('Error fetching daily finance summary:', error);
    return sendError(res, error.message || 'Failed to fetch daily finance summary');
  }
});

financeRouter.get('/expenses', async (_req, res) => {
  try {
    const expenses = await prisma.expense.findMany({
      orderBy: {
        expenseDate: 'desc'
      }
    });
    return sendSuccess(res, { expenses }, 'Expenses fetched successfully');
  } catch (error: any) {
    return sendError(res, error.message || 'Failed to fetch expenses');
  }
});
