import { Router } from 'express';

export const reportsRouter = Router();

reportsRouter.get('/sales', (req, res) => {
  const { from, to, employeeId } = req.query;

  res.json({
    filters: {
      from: typeof from === 'string' ? from : undefined,
      to: typeof to === 'string' ? to : undefined,
      employeeId: typeof employeeId === 'string' ? employeeId : undefined,
    },
    bookedOrders: 0,
    deliveredOrders: 0,
    revenue: 0,
  });
});
