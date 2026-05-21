import { Router } from 'express';

export const settingsRouter = Router();

settingsRouter.get('/store', (_req, res) => {
  res.json({
    storeName: 'Retail Lens',
    gstNumber: null,
    address: null,
  });
});

settingsRouter.put('/store', (req, res) => {
  const payload = req.body as {
    storeName?: string;
    gstNumber?: string;
    address?: string;
  };

  res.json({
    storeName: payload.storeName ?? 'Retail Lens',
    gstNumber: payload.gstNumber ?? null,
    address: payload.address ?? null,
    updatedAt: new Date().toISOString(),
  });
});
