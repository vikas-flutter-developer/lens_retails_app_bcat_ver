import { Router } from 'express';

export const employeesRouter = Router();

employeesRouter.get('/:id/tasks', (req, res) => {
  res.json({
    employeeId: req.params.id,
    assigned: 0,
    completed: 0,
    pending: 0,
  });
});
