import { Router } from 'express';

export const jobCardsRouter = Router();

jobCardsRouter.post('/', (req, res) => {
  const { customerId } = req.body as { customerId?: string };

  res.status(201).json({
    id: 'jc_demo',
    customerId: customerId ?? null,
    status: 'DRAFT',
    createdAt: new Date().toISOString(),
  });
});

jobCardsRouter.get('/:id', (req, res) => {
  res.json({
    id: req.params.id,
    status: 'DRAFT',
    items: [],
    payments: [],
  });
});

jobCardsRouter.delete('/:id/items/:itemId', (req, res) => {
  res.json({
    jobCardId: req.params.id,
    itemId: req.params.itemId,
    removed: true,
  });
});

jobCardsRouter.post('/:id/payments', (req, res) => {
  const payload = req.body as {
    amount?: number;
    paymentType?: string;
    idempotencyKey?: string;
  };

  res.status(201).json({
    id: 'payment_demo',
    jobCardId: req.params.id,
    amount: payload.amount ?? 0,
    paymentType: payload.paymentType ?? 'CASH',
    idempotencyKey: payload.idempotencyKey ?? null,
    recordedAt: new Date().toISOString(),
  });
});
