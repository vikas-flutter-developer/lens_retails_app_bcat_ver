import { Router } from 'express';

export const tasksRouter = Router();

tasksRouter.get('/', (_req, res) => {
  res.json({
    summary: {
      pending: 0,
      inProgress: 0,
      completed: 0,
    },
    tasks: [],
  });
});
