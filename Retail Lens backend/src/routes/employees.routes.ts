import { Router } from 'express';
import { EmployeesController } from '../controllers/employees.controller';

export const employeesRouter = Router();

employeesRouter.get('/', EmployeesController.getEmployees);
employeesRouter.get('/all/tasks', EmployeesController.getEmployeesForTasks);
employeesRouter.post('/', EmployeesController.createEmployee);
employeesRouter.put('/:id', EmployeesController.updateEmployee);
employeesRouter.patch('/:id', EmployeesController.updateEmployee);
employeesRouter.delete('/:id', EmployeesController.deleteEmployee);

// Task counts route
employeesRouter.get('/:id/tasks', EmployeesController.getEmployeeTaskCounts);


