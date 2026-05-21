import { Router } from 'express';

export const authRouter = Router();

authRouter.post('/login', (req, res) => {
  const { email } = req.body as { email?: string };

  res.json({
    user: { id: 'demo-user', email: email ?? '', role: 'OWNER' },
    accessToken: 'replace-with-jwt-token',
    refreshToken: 'replace-with-refresh-token',
  });
});

authRouter.post('/refresh', (_req, res) => {
  res.json({ accessToken: 'replace-with-jwt-token' });
});
