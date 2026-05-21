"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.jobCardsRouter = void 0;
const express_1 = require("express");
const client_1 = require("../prisma/client");
const inventory_sync_util_1 = require("../utils/inventory-sync.util");
exports.jobCardsRouter = (0, express_1.Router)();
exports.jobCardsRouter.post('/', async (req, res) => {
    try {
        const { customerId, title, priority, notes, expectedCompletionDate, billNo, billSeries, orderType, bookedBy, godown, totalAmount, paidAmount, dueAmount, items, payments } = req.body;
        if (!customerId) {
            return res.status(400).json({ error: 'customerId is required' });
        }
        let customer = await client_1.prisma.customer.findUnique({
            where: { id: customerId },
        });
        if (!customer) {
            customer = await client_1.prisma.customer.create({
                data: {
                    id: customerId,
                    fullName: 'Default Customer',
                    phone: '99999999' + Math.floor(Math.random() * 90 + 10),
                },
            });
        }
        const jobCard = await client_1.prisma.jobCard.create({
            data: {
                customerId: customer.id,
                title: title || null,
                priority: priority || 'Medium',
                notes: notes || null,
                expectedCompletionDate: expectedCompletionDate ? new Date(expectedCompletionDate) : null,
                billNo: billNo || null,
                billSeries: billSeries || null,
                orderType: orderType || null,
                bookedBy: bookedBy || null,
                godown: godown || null,
                totalAmount: totalAmount !== undefined ? totalAmount : 0,
                paidAmount: paidAmount !== undefined ? paidAmount : 0,
                dueAmount: dueAmount !== undefined ? dueAmount : 0,
                status: 'DRAFT',
                items: Array.isArray(items) ? {
                    create: items.map((item) => {
                        const quantity = item.quantity !== undefined ? Number(item.quantity) : 1;
                        const unitPrice = item.unitPrice !== undefined ? Number(item.unitPrice) : 0;
                        const lineTotal = item.lineTotal !== undefined ? Number(item.lineTotal) : (quantity * unitPrice);
                        return {
                            productId: item.productId || null,
                            description: item.description || item.itemName || 'Service Item',
                            quantity,
                            unitPrice,
                            lineTotal,
                            sph: item.sph || null,
                            cyl: item.cyl || null,
                            axis: item.axis || null,
                            add: item.add || null,
                            eye: item.eye || null,
                        };
                    }),
                } : undefined,
                payments: Array.isArray(payments) ? {
                    create: payments.map((payment) => ({
                        amount: payment.amount !== undefined ? Number(payment.amount) : 0,
                        paymentType: (payment.paymentType || 'CASH').toUpperCase(),
                        idempotencyKey: payment.idempotencyKey || null,
                    })),
                } : undefined,
            },
            include: {
                items: true,
                payments: true,
            },
        });
        res.status(201).json(jobCard);
    }
    catch (error) {
        console.error('Error in job-cards POST:', error);
        res.status(500).json({ error: error.message || 'Internal server error' });
    }
});
exports.jobCardsRouter.get('/', async (req, res) => {
    try {
        const jobCards = await client_1.prisma.jobCard.findMany({
            include: {
                items: true,
                payments: true,
                customer: true,
            },
            orderBy: {
                createdAt: 'desc',
            },
        });
        res.json(jobCards);
    }
    catch (error) {
        res.status(500).json({ error: error.message || 'Internal server error' });
    }
});
exports.jobCardsRouter.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const jobCard = await client_1.prisma.jobCard.findUnique({
            where: { id },
            include: {
                items: true,
                payments: true,
                customer: true,
            },
        });
        if (!jobCard) {
            return res.status(404).json({ error: 'JobCard not found' });
        }
        res.json(jobCard);
    }
    catch (error) {
        res.status(500).json({ error: error.message || 'Internal server error' });
    }
});
exports.jobCardsRouter.put('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { status, title, priority, notes, expectedCompletionDate } = (req.body || {});
        const jobCard = await client_1.prisma.jobCard.findUnique({
            where: { id },
        });
        if (!jobCard) {
            return res.status(404).json({ error: 'JobCard not found' });
        }
        const oldStatus = jobCard.status;
        const targetStatus = status || jobCard.status;
        const updatedJobCard = await client_1.prisma.jobCard.update({
            where: { id },
            data: {
                status: targetStatus,
                title: title !== undefined ? title : jobCard.title,
                priority: priority !== undefined ? priority : jobCard.priority,
                notes: notes !== undefined ? notes : jobCard.notes,
                expectedCompletionDate: expectedCompletionDate ? new Date(expectedCompletionDate) : jobCard.expectedCompletionDate,
            },
            include: {
                items: true,
                payments: true,
            },
        });
        await (0, inventory_sync_util_1.syncInventoryOnStatusChange)(id, oldStatus, targetStatus);
        res.json(updatedJobCard);
    }
    catch (error) {
        console.error('Error in JobCard PUT:', error);
        res.status(500).json({ error: error.message || 'Internal server error' });
    }
});
exports.jobCardsRouter.delete('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const jobCard = await client_1.prisma.jobCard.findUnique({
            where: { id },
        });
        if (!jobCard) {
            return res.status(404).json({ error: 'JobCard not found' });
        }
        await client_1.prisma.jobCardItem.deleteMany({
            where: { jobCardId: id },
        });
        await client_1.prisma.payment.deleteMany({
            where: { jobCardId: id },
        });
        await client_1.prisma.jobCard.delete({
            where: { id },
        });
        res.json({
            id,
            deleted: true,
        });
    }
    catch (error) {
        console.error('Error in JobCard DELETE:', error);
        res.status(500).json({ error: error.message || 'Internal server error' });
    }
});
exports.jobCardsRouter.delete('/:id/items/:itemId', async (req, res) => {
    try {
        const { id, itemId } = req.params;
        const item = await client_1.prisma.jobCardItem.findFirst({
            where: {
                id: itemId,
                jobCardId: id,
            },
        });
        if (!item) {
            return res.status(404).json({ error: 'Item not found in this JobCard' });
        }
        await client_1.prisma.jobCardItem.delete({
            where: { id: itemId },
        });
        const jobCard = await client_1.prisma.jobCard.findUnique({ where: { id } });
        if (jobCard) {
            const allItems = await client_1.prisma.jobCardItem.findMany({ where: { jobCardId: id } });
            const totalAmount = allItems.reduce((sum, item) => sum + Number(item.lineTotal), 0);
            const dueAmount = Math.max(0, totalAmount - Number(jobCard.paidAmount));
            await client_1.prisma.jobCard.update({
                where: { id },
                data: {
                    totalAmount,
                    dueAmount,
                },
            });
        }
        res.json({
            jobCardId: id,
            itemId: itemId,
            removed: true,
        });
    }
    catch (error) {
        res.status(500).json({ error: error.message || 'Internal server error' });
    }
});
exports.jobCardsRouter.post('/:id/payments', async (req, res) => {
    try {
        const { id } = req.params;
        const { amount, paymentType, idempotencyKey, amountCollected, paymentMode } = req.body;
        const finalAmount = amount !== undefined ? amount : amountCollected;
        const finalType = paymentType || paymentMode;
        const jobCard = await client_1.prisma.jobCard.findUnique({
            where: { id },
        });
        if (!jobCard) {
            return res.status(404).json({ error: 'JobCard not found' });
        }
        if (idempotencyKey) {
            const existingPayment = await client_1.prisma.payment.findUnique({
                where: { idempotencyKey },
            });
            if (existingPayment) {
                return res.status(200).json(existingPayment);
            }
        }
        const paymentAmount = finalAmount !== undefined ? Number(finalAmount) : 0;
        const payment = await client_1.prisma.payment.create({
            data: {
                jobCardId: id,
                amount: paymentAmount,
                paymentType: (finalType || 'CASH').toUpperCase(),
                idempotencyKey: idempotencyKey || null,
            },
        });
        const allPayments = await client_1.prisma.payment.findMany({
            where: { jobCardId: id },
        });
        const totalPaid = allPayments.reduce((sum, p) => sum + Number(p.amount), 0);
        const totalAmount = Number(jobCard.totalAmount);
        const dueAmount = Math.max(0, totalAmount - totalPaid);
        await client_1.prisma.jobCard.update({
            where: { id },
            data: {
                paidAmount: totalPaid,
                dueAmount: dueAmount,
            },
        });
        res.status(201).json(payment);
    }
    catch (error) {
        console.error('Error in POST payments:', error);
        res.status(500).json({ error: error.message || 'Internal server error' });
    }
});
exports.jobCardsRouter.post('/:id/items', async (req, res) => {
    try {
        const { id } = req.params;
        const { productId, description, quantity, unitPrice, lineTotal, sph, cyl, axis, add, eye } = req.body;
        const jobCard = await client_1.prisma.jobCard.findUnique({ where: { id } });
        if (!jobCard) {
            return res.status(404).json({ error: 'JobCard not found' });
        }
        const q = quantity !== undefined ? Number(quantity) : 1;
        const up = unitPrice !== undefined ? Number(unitPrice) : 0;
        const lt = lineTotal !== undefined ? Number(lineTotal) : (q * up);
        const newItem = await client_1.prisma.jobCardItem.create({
            data: {
                jobCardId: id,
                productId: productId || null,
                description: description || 'Service Item',
                quantity: q,
                unitPrice: up,
                lineTotal: lt,
                sph: sph || null,
                cyl: cyl || null,
                axis: axis || null,
                add: add || null,
                eye: eye || null,
            },
        });
        const allItems = await client_1.prisma.jobCardItem.findMany({ where: { jobCardId: id } });
        const totalAmount = allItems.reduce((sum, item) => sum + Number(item.lineTotal), 0);
        const dueAmount = Math.max(0, totalAmount - Number(jobCard.paidAmount));
        await client_1.prisma.jobCard.update({
            where: { id },
            data: {
                totalAmount,
                dueAmount,
            },
        });
        res.status(201).json(newItem);
    }
    catch (error) {
        console.error('Error in POST item:', error);
        res.status(500).json({ error: error.message || 'Internal server error' });
    }
});
exports.jobCardsRouter.delete('/:id/payments/:paymentId', async (req, res) => {
    try {
        const { id, paymentId } = req.params;
        const payment = await client_1.prisma.payment.findFirst({
            where: { id: paymentId, jobCardId: id },
        });
        if (!payment) {
            return res.status(404).json({ error: 'Payment not found in this JobCard' });
        }
        await client_1.prisma.payment.delete({
            where: { id: paymentId },
        });
        const jobCard = await client_1.prisma.jobCard.findUnique({ where: { id } });
        if (jobCard) {
            const allPayments = await client_1.prisma.payment.findMany({ where: { jobCardId: id } });
            const totalPaid = allPayments.reduce((sum, p) => sum + Number(p.amount), 0);
            const dueAmount = Math.max(0, Number(jobCard.totalAmount) - totalPaid);
            await client_1.prisma.jobCard.update({
                where: { id },
                data: {
                    paidAmount: totalPaid,
                    dueAmount: dueAmount,
                },
            });
        }
        res.json({
            jobCardId: id,
            paymentId: paymentId,
            removed: true,
        });
    }
    catch (error) {
        console.error('Error in DELETE payment:', error);
        res.status(500).json({ error: error.message || 'Internal server error' });
    }
});
exports.jobCardsRouter.get('/customer/:customerId', async (req, res) => {
    try {
        const { customerId } = req.params;
        const jobCards = await client_1.prisma.jobCard.findMany({
            where: { customerId },
            include: {
                items: true,
                payments: true,
                customer: true,
            },
            orderBy: {
                createdAt: 'desc',
            },
        });
        res.json(jobCards);
    }
    catch (error) {
        console.error('Error in GET by customer:', error);
        res.status(500).json({ error: error.message || 'Internal server error' });
    }
});
exports.jobCardsRouter.get('/:id/invoice', async (req, res) => {
    try {
        const { id } = req.params;
        const jobCard = await client_1.prisma.jobCard.findUnique({
            where: { id },
            include: {
                items: true,
                payments: true,
                customer: true,
            },
        });
        if (!jobCard) {
            return res.status(404).json({ error: 'JobCard not found' });
        }
        const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <title>Invoice - ${jobCard.billNo || jobCard.id}</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 30px; color: #333; }
          .header { text-align: center; margin-bottom: 30px; }
          .invoice-box { border: 1px solid #eee; padding: 30px; max-width: 800px; margin: auto; }
          .flex { display: flex; justify-content: space-between; }
          table { width: 100%; border-collapse: collapse; margin-top: 20px; }
          th, td { border: 1px solid #ddd; padding: 10px; text-align: left; }
          th { background-color: #f5f5f5; }
          .totals { margin-top: 20px; text-align: right; font-size: 1.1em; }
        </style>
      </head>
      <body>
        <div class="invoice-box">
          <div class="header">
            <h2>RETAIL LENS OPTICALS</h2>
            <p>Premium Lens & Eyewear Solutions</p>
          </div>
          <div class="flex">
            <div>
              <strong>Customer:</strong> ${jobCard.customer?.fullName || 'Walk-in'}<br>
              <strong>Phone:</strong> ${jobCard.customer?.phone || 'N/A'}
            </div>
            <div>
              <strong>Bill No:</strong> ${jobCard.billNo || 'N/A'}<br>
              <strong>Date:</strong> ${jobCard.createdAt.toLocaleDateString()}<br>
              <strong>Status:</strong> ${jobCard.status}
            </div>
          </div>
          <table>
            <thead>
              <tr>
                <th>Description</th>
                <th>Sph</th>
                <th>Cyl</th>
                <th>Axis</th>
                <th>Add</th>
                <th>Qty</th>
                <th>Price</th>
                <th>Total</th>
              </tr>
            </thead>
            <tbody>
              ${jobCard.items.map(item => `
                <tr>
                  <td>${item.description}</td>
                  <td>${item.sph || ''}</td>
                  <td>${item.cyl || ''}</td>
                  <td>${item.axis || ''}</td>
                  <td>${item.add || ''}</td>
                  <td>${item.quantity}</td>
                  <td>₹${item.unitPrice}</td>
                  <td>₹${item.lineTotal}</td>
                </tr>
              `).join('')}
            </tbody>
          </table>
          <div class="totals">
            <p><strong>Total Amount:</strong> ₹${jobCard.totalAmount}</p>
            <p><strong>Paid Amount:</strong> ₹${jobCard.paidAmount}</p>
            <p style="color: red;"><strong>Due Amount:</strong> ₹${jobCard.dueAmount}</p>
          </div>
        </div>
      </body>
      </html>
    `;
        res.setHeader('Content-Type', 'text/html');
        res.send(html);
    }
    catch (error) {
        console.error('Error generating invoice:', error);
        res.status(500).json({ error: error.message || 'Internal server error' });
    }
});
exports.jobCardsRouter.patch('/:id/status', async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;
        if (!status) {
            return res.status(400).json({ error: 'status is required' });
        }
        const jobCard = await client_1.prisma.jobCard.findUnique({ where: { id } });
        if (!jobCard) {
            return res.status(404).json({ error: 'JobCard not found' });
        }
        const oldStatus = jobCard.status;
        const updated = await client_1.prisma.jobCard.update({
            where: { id },
            data: { status },
        });
        await (0, inventory_sync_util_1.syncInventoryOnStatusChange)(id, oldStatus, status);
        res.json(updated);
    }
    catch (error) {
        console.error('Error patching status:', error);
        res.status(500).json({ error: error.message || 'Internal server error' });
    }
});
exports.jobCardsRouter.post('/scan-status', async (req, res) => {
    try {
        const { jobCardId, targetStatus } = req.body;
        if (!jobCardId || !targetStatus) {
            return res.status(400).json({ error: 'jobCardId and targetStatus are required' });
        }
        if (jobCardId.includes('DEMO') || jobCardId.includes('MOCK') || jobCardId === 'YOUR-QR-CODE') {
            return res.json({ success: true, message: `MOCK Job Card transitioned to ${targetStatus}` });
        }
        const jobCard = await client_1.prisma.jobCard.findUnique({ where: { id: jobCardId } });
        if (!jobCard) {
            return res.status(404).json({ error: `JobCard ${jobCardId} not found` });
        }
        const oldStatus = jobCard.status;
        const updated = await client_1.prisma.jobCard.update({
            where: { id: jobCardId },
            data: { status: targetStatus },
        });
        await (0, inventory_sync_util_1.syncInventoryOnStatusChange)(jobCardId, oldStatus, targetStatus);
        res.json({
            success: true,
            message: `Job Card moved to ${targetStatus}`,
            data: updated
        });
    }
    catch (error) {
        console.error('Error in scan-status handler:', error);
        res.status(500).json({ error: error.message || 'Internal server error' });
    }
});
//# sourceMappingURL=job-cards.routes.js.map