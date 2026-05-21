import { Router } from 'express';

export const syncRouter = Router();

syncRouter.post('/', (req, res) => {
  const payload = req.body as {
    deviceId?: string;
    idempotencyKey?: string;
    actions?: Array<{ actionType: string; payload: unknown }>;
  };

  res.status(202).json({
    batchId: 'sync_batch_demo',
    deviceId: payload.deviceId ?? '',
    accepted: payload.actions?.length ?? 0,
    conflicts: [],
    idempotencyKey: payload.idempotencyKey ?? null,
  });
});
