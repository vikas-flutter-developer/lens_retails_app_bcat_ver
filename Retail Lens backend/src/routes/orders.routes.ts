import { Router } from 'express';
import { OrdersController } from '../controllers/orders.controller';
import { prisma } from '../prisma/client';

export const ordersRouter = Router();

ordersRouter.get('/', OrdersController.getOrders);
ordersRouter.post('/', OrdersController.createOrder);
ordersRouter.patch('/:id', OrdersController.updateOrder);

// Support recording customer payments via /orders/:id/payments as well
ordersRouter.post('/:id/payments', async (req, res) => {
  try {
    const { id } = req.params;
    const { amount, paymentType, idempotencyKey, amountCollected, paymentMode } = req.body as {
      amount?: number;
      paymentType?: string;
      idempotencyKey?: string;
      amountCollected?: number;
      paymentMode?: string;
    };

    const finalAmount = amount !== undefined ? amount : amountCollected;
    const finalType = paymentType || paymentMode;

    // 1. Verify JobCard exists
    const jobCard = await prisma.jobCard.findUnique({
      where: { id },
    });

    if (!jobCard) {
      return res.status(404).json({ error: 'JobCard not found' });
    }

    // 2. Stripe-like idempotency protection: check if payment key was already processed
    if (idempotencyKey) {
      const existingPayment = await prisma.payment.findUnique({
        where: { idempotencyKey },
      });
      if (existingPayment) {
        return res.status(200).json(existingPayment);
      }
    }

    // 3. Create the payment record in the database
    const paymentAmount = finalAmount !== undefined ? Number(finalAmount) : 0;
    const payment = await prisma.payment.create({
      data: {
        jobCardId: id,
        amount: paymentAmount,
        paymentType: (finalType || 'CASH').toUpperCase() as any,
        idempotencyKey: idempotencyKey || null,
      },
    });

    // 4. Automatically calculate and update paidAmount and dueAmount on the parent JobCard
    const allPayments = await prisma.payment.findMany({
      where: { jobCardId: id },
    });

    const totalPaid = allPayments.reduce((sum, p) => sum + Number(p.amount), 0);
    const totalAmount = Number(jobCard.totalAmount);
    const dueAmount = Math.max(0, totalAmount - totalPaid);

    await prisma.jobCard.update({
      where: { id },
      data: {
        paidAmount: totalPaid,
        dueAmount: dueAmount,
      },
    });

    res.status(201).json({
      success: true,
      message: 'Payment recorded successfully',
      data: payment
    });
  } catch (error: any) {
    console.error('Error in POST payments:', error);
    res.status(500).json({ error: error.message || 'Internal server error' });
  }
});
