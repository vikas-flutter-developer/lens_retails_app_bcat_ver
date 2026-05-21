"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TasksController = void 0;
const tasks_service_1 = require("../services/tasks.service");
const response_util_1 = require("../utils/response.util");
class TasksController {
    static async getTasks(req, res) {
        try {
            const tasks = await tasks_service_1.TasksService.getAllTasks();
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
            return (0, response_util_1.sendSuccess)(res, { data: formattedTasks }, 'Tasks fetched successfully');
        }
        catch (error) {
            console.error('Error fetching tasks:', error);
            return (0, response_util_1.sendError)(res, error.message || 'Failed to fetch tasks');
        }
    }
    static async createTask(req, res) {
        try {
            const { title, description, assignedTo, status, priority, dueDate } = req.body;
            if (!title || !assignedTo) {
                return (0, response_util_1.sendError)(res, 'Title and assigned employee are required', 400);
            }
            const normalizedStatus = status
                ? status.toUpperCase().replace(/\s+/g, '_')
                : undefined;
            const normalizedPriority = priority
                ? priority.toUpperCase().replace(/\s+/g, '_')
                : undefined;
            const task = await tasks_service_1.TasksService.createTask({
                title,
                description,
                assignedToId: assignedTo,
                status: normalizedStatus,
                priority: normalizedPriority,
                dueDate
            });
            return (0, response_util_1.sendSuccess)(res, {
                data: {
                    id: task.id
                }
            }, 'Task created successfully', 201);
        }
        catch (error) {
            console.error('Error creating task:', error);
            if (error.message === 'Assigned employee not found') {
                return (0, response_util_1.sendError)(res, error.message, 404);
            }
            return (0, response_util_1.sendError)(res, error.message || 'Failed to create task');
        }
    }
    static async updateTaskStatus(req, res) {
        try {
            const { id } = req.params;
            const { status } = req.body;
            if (!status) {
                return (0, response_util_1.sendError)(res, 'Status is required', 400);
            }
            await tasks_service_1.TasksService.updateTaskStatus(id, status);
            return (0, response_util_1.sendSuccess)(res, {}, 'Task status updated successfully');
        }
        catch (error) {
            console.error('Error updating task status:', error);
            if (error.code === 'P2025' || error.message === 'Task not found') {
                return (0, response_util_1.sendError)(res, 'Task not found', 404);
            }
            return (0, response_util_1.sendError)(res, error.message || 'Failed to update task status');
        }
    }
    static async updateTask(req, res) {
        try {
            const { id } = req.params;
            const { title, description, assignedTo, status, priority, dueDate } = req.body;
            const normalizedStatus = status
                ? status.toUpperCase().replace(/\s+/g, '_')
                : undefined;
            const normalizedPriority = priority
                ? priority.toUpperCase().replace(/\s+/g, '_')
                : undefined;
            const task = await tasks_service_1.TasksService.updateTask(id, {
                title,
                description,
                assignedToId: assignedTo,
                status: normalizedStatus,
                priority: normalizedPriority,
                dueDate
            });
            return (0, response_util_1.sendSuccess)(res, { data: { id: task.id } }, 'Task updated successfully');
        }
        catch (error) {
            console.error('Error updating task:', error);
            if (error.code === 'P2025' || error.message === 'Task not found') {
                return (0, response_util_1.sendError)(res, 'Task not found', 404);
            }
            if (error.message === 'Assigned employee not found') {
                return (0, response_util_1.sendError)(res, error.message, 404);
            }
            return (0, response_util_1.sendError)(res, error.message || 'Failed to update task');
        }
    }
    static async deleteTask(req, res) {
        try {
            const { id } = req.params;
            await tasks_service_1.TasksService.deleteTask(id);
            return (0, response_util_1.sendSuccess)(res, {}, 'Task deleted successfully');
        }
        catch (error) {
            console.error('Error deleting task:', error);
            if (error.code === 'P2025' || error.message === 'Task not found') {
                return (0, response_util_1.sendError)(res, 'Task not found', 404);
            }
            return (0, response_util_1.sendError)(res, error.message || 'Failed to delete task');
        }
    }
}
exports.TasksController = TasksController;
//# sourceMappingURL=tasks.controller.js.map