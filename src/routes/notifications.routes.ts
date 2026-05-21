import { Router } from 'express';

export const notificationsRouter = Router();

notificationsRouter.post('/send', (req, res) => {
  const payload = req.body as {
    channel?: 'WHATSAPP' | 'EMAIL';
    recipient?: string;
    message?: string;
  };

  res.status(202).json({
    id: 'notification_demo',
    status: 'queued',
    channel: payload.channel ?? 'WHATSAPP',
    recipient: payload.recipient ?? '',
    message: payload.message ?? '',
    queuedAt: new Date().toISOString(),
  });
});
