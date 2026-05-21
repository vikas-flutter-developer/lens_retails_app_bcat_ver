import { Router } from 'express';
import { TasksController } from '../controllers/tasks.controller';

export const tasksRouter = Router();

tasksRouter.get('/', TasksController.getTasks);
tasksRouter.post('/', TasksController.createTask);
tasksRouter.patch('/:id', TasksController.updateTaskStatus);
tasksRouter.put('/:id', TasksController.updateTask);
tasksRouter.delete('/:id', TasksController.deleteTask);
