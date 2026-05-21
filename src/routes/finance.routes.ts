import { Router } from 'express';

export const financeRouter = Router();

financeRouter.get('/daily-summary', (_req, res) => {
  res.json({
    cashInHand: 0,
    salesToday: 0,
    deliveriesToday: 0,
    framesSoldToday: 0,
  });
});

financeRouter.post('/expenses', (req, res) => {
  const payload = req.body as { title?: string; amount?: number; notes?: string };

  res.status(201).json({
    id: 'expense_demo',
    title: payload.title ?? '',
    amount: payload.amount ?? 0,
    notes: payload.notes ?? null,
    createdAt: new Date().toISOString(),
  });
});

financeRouter.put('/expenses/:id', (req, res) => {
  const payload = req.body as { title?: string; amount?: number; notes?: string };

  res.json({
    id: req.params.id,
    ...payload,
    updatedAt: new Date().toISOString(),
  });
});

financeRouter.delete('/expenses/:id', (req, res) => {
  res.json({ id: req.params.id, deleted: true });
});
