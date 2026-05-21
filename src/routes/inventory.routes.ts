import { Router } from 'express';

export const inventoryRouter = Router();

inventoryRouter.post('/', (req, res) => {
  const payload = req.body as {
    sku?: string;
    name?: string;
    kind?: 'FRAME' | 'LENS' | 'ACCESSORY';
  };

  res.status(201).json({
    id: 'inv_demo',
    sku: payload.sku ?? '',
    name: payload.name ?? '',
    kind: payload.kind ?? 'FRAME',
    stockQuantity: 0,
  });
});

inventoryRouter.get('/', (_req, res) => {
  res.json([]);
});

inventoryRouter.put('/:id', (req, res) => {
  const { quantity } = req.body as { quantity?: number };

  res.json({
    id: req.params.id,
    stockQuantity: quantity ?? 0,
    updated: true,
  });
});

inventoryRouter.get('/:id/history', (req, res) => {
  res.json({ id: req.params.id, movements: [] });
});

inventoryRouter.get('/alerts', (_req, res) => {
  res.json([]);
});
