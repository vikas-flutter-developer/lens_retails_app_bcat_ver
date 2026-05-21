import { Request, Response } from 'express';
import { TasksService } from '../services/tasks.service';
import { sendSuccess, sendError } from '../utils/response.util';
import { TaskStatus, Priority } from '@prisma/client';

export class TasksController {
  static async getTasks(req: Request, res: Response) {
    try {
      const tasks = await TasksService.getAllTasks();
      
      const formattedTasks = tasks.map(task => ({
        id: task.id,
        title: task.title,
        description: task.description || '',
        status: task.status,
        priority: task.priority,
        dueDate: task.dueDate || '',
        assignedTo: task.assignedTo ? {
          id: task.assignedTo.id,
          name: task.assignedTo.name
        } : null
      }));

      return sendSuccess(res, { data: formattedTasks }, 'Tasks fetched successfully');
    } catch (error: any) {
      console.error('Error fetching tasks:', error);
      return sendError(res, error.message || 'Failed to fetch tasks');
    }
  }

  static async createTask(req: Request, res: Response) {
    try {
      const { title, description, assignedTo, status, priority, dueDate } = req.body;

      if (!title || !assignedTo) {
        return sendError(res, 'Title and assigned employee are required', 400);
      }

      // Normalize enum values to match Prisma keys (e.g., "In Progress" -> "IN_PROGRESS")
      const normalizedStatus = status 
        ? (status as string).toUpperCase().replace(/\s+/g, '_') as TaskStatus 
        : undefined;
      
      const normalizedPriority = priority 
        ? (priority as string).toUpperCase().replace(/\s+/g, '_') as Priority 
        : undefined;

      const task = await TasksService.createTask({
        title,
        description,
        assignedToId: assignedTo,
        status: normalizedStatus,
        priority: normalizedPriority,
        dueDate
      });

      return sendSuccess(
        res,
        { 
          data: {
            id: task.id
          } 
        },
        'Task created successfully',
        201
      );
    } catch (error: any) {
      console.error('Error creating task:', error);
      if (error.message === 'Assigned employee not found') {
        return sendError(res, error.message, 404);
      }
      return sendError(res, error.message || 'Failed to create task');
    }
  }

  static async updateTaskStatus(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const { status } = req.body;

      if (!status) {
        return sendError(res, 'Status is required', 400);
      }

      await TasksService.updateTaskStatus(id as string, status as TaskStatus);
      return sendSuccess(res, {}, 'Task status updated successfully');
    } catch (error: any) {
      console.error('Error updating task status:', error);
      if (error.code === 'P2025' || error.message === 'Task not found') {
        return sendError(res, 'Task not found', 404);
      }
      return sendError(res, error.message || 'Failed to update task status');
    }
  }

  static async updateTask(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const { title, description, assignedTo, status, priority, dueDate } = req.body;

      // Normalize enum values to match Prisma keys if provided
      const normalizedStatus = status 
        ? (status as string).toUpperCase().replace(/\s+/g, '_') as TaskStatus 
        : undefined;
      
      const normalizedPriority = priority 
        ? (priority as string).toUpperCase().replace(/\s+/g, '_') as Priority 
        : undefined;

      const task = await TasksService.updateTask(id as string, {
        title,
        description,
        assignedToId: assignedTo,
        status: normalizedStatus,
        priority: normalizedPriority,
        dueDate
      });

      return sendSuccess(res, { data: { id: task.id } }, 'Task updated successfully');
    } catch (error: any) {
      console.error('Error updating task:', error);
      if (error.code === 'P2025' || error.message === 'Task not found') {
        return sendError(res, 'Task not found', 404);
      }
      if (error.message === 'Assigned employee not found') {
        return sendError(res, error.message, 404);
      }
      return sendError(res, error.message || 'Failed to update task');
    }
  }

  static async deleteTask(req: Request, res: Response) {
    try {
      const { id } = req.params;
      await TasksService.deleteTask(id as string);
      return sendSuccess(res, {}, 'Task deleted successfully');
    } catch (error: any) {
      console.error('Error deleting task:', error);
      if (error.code === 'P2025' || error.message === 'Task not found') {
        return sendError(res, 'Task not found', 404);
      }
      return sendError(res, error.message || 'Failed to delete task');
    }
  }
}
