"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.financeRouter = void 0;
const express_1 = require("express");
const client_1 = require("../prisma/client");
const response_util_1 = require("../utils/response.util");
exports.financeRouter = (0, express_1.Router)();
exports.financeRouter.get('/daily-summary', async (req, res) => {
    try {
        const { date, isMonthly } = req.query;
        const targetDate = date ? new Date(date) : new Date();
        const startOfDay = new Date(targetDate);
        if (isMonthly === 'true') {
            startOfDay.setDate(1);
        }
        startOfDay.setHours(0, 0, 0, 0);
        const endOfDay = new Date(targetDate);
        endOfDay.setHours(23, 59, 59, 999);
        const payments = await client_1.prisma.payment.findMany({
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
        const expenses = await client_1.prisma.expense.findMany({
            where: {
                expenseDate: {
                    gte: startOfDay,
                    lte: endOfDay
                }
            }
        });
        const totalExpensesPaid = expenses.reduce((sum, e) => sum + Number(e.amount), 0);
        const sales = await client_1.prisma.jobCard.findMany({
            where: {
                createdAt: {
                    gte: startOfDay,
                    lte: endOfDay
                }
            }
        });
        const totalSalesToday = sales.reduce((sum, j) => sum + Number(j.totalAmount), 0);
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
        const jobCardItems = await client_1.prisma.jobCardItem.findMany({
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
        return (0, response_util_1.sendSuccess)(res, { data: financeData }, 'Daily finance summary fetched successfully');
    }
    catch (error) {
        console.error('Error fetching daily finance summary:', error);
        return (0, response_util_1.sendError)(res, error.message || 'Failed to fetch daily finance summary');
    }
});
exports.financeRouter.get('/expenses', async (_req, res) => {
    try {
        const expenses = await client_1.prisma.expense.findMany({
            orderBy: {
                expenseDate: 'desc'
            }
        });
        return (0, response_util_1.sendSuccess)(res, { expenses }, 'Expenses fetched successfully');
    }
    catch (error) {
        return (0, response_util_1.sendError)(res, error.message || 'Failed to fetch expenses');
    }
});
//# sourceMappingURL=finance.routes.js.map