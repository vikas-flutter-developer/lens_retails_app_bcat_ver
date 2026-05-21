"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TasksService = void 0;
const client_1 = require("../prisma/client");
const client_2 = require("@prisma/client");
class TasksService {
    static async getAllTasks() {
        return await client_1.prisma.task.findMany({
            include: {
                assignedTo: {
                    select: {
                        id: true,
                        name: true,
                    },
                },
            },
            orderBy: {
                createdAt: 'desc',
            },
        });
    }
    static async createTask(data) {
        let employee = await client_1.prisma.employee.findUnique({
            where: { id: data.assignedToId },
        });
        if (!employee) {
            employee = await client_1.prisma.employee.findFirst({
                where: { name: data.assignedToId },
            });
        }
        if (!employee) {
            throw new Error('Assigned employee not found');
        }
        return await client_1.prisma.task.create({
            data: {
                title: data.title,
                description: data.description,
                assignedToId: employee.id,
                status: data.status || client_2.TaskStatus.PENDING,
                priority: data.priority || client_2.Priority.MEDIUM,
                dueDate: data.dueDate,
            },
        });
    }
    static async updateTaskStatus(id, status) {
        const task = await client_1.prisma.task.findUnique({
            where: { id },
        });
        if (!task) {
            const error = new Error('Task not found');
            error.code = 'P2025';
            throw error;
        }
        return await client_1.prisma.task.update({
            where: { id },
            data: { status },
        });
    }
    static async updateTask(id, data) {
        const task = await client_1.prisma.task.findUnique({
            where: { id },
        });
        if (!task) {
            const error = new Error('Task not found');
            error.code = 'P2025';
            throw error;
        }
        let employeeId = data.assignedToId;
        if (employeeId) {
            let employee = await client_1.prisma.employee.findUnique({
                where: { id: employeeId },
            });
            if (!employee) {
                employee = await client_1.prisma.employee.findFirst({
                    where: { name: employeeId },
                });
            }
            if (!employee) {
                throw new Error('Assigned employee not found');
            }
            employeeId = employee.id;
        }
        return await client_1.prisma.task.update({
            where: { id },
            data: {
                title: data.title !== undefined ? data.title : task.title,
                description: data.description !== undefined ? data.description : task.description,
                assignedToId: employeeId !== undefined ? employeeId : task.assignedToId,
                status: data.status !== undefined ? data.status : task.status,
                priority: data.priority !== undefined ? data.priority : task.priority,
                dueDate: data.dueDate !== undefined ? data.dueDate : task.dueDate,
            },
        });
    }
    static async deleteTask(id) {
        const task = await client_1.prisma.task.findUnique({
            where: { id },
        });
        if (!task) {
            const error = new Error('Task not found');
            error.code = 'P2025';
            throw error;
        }
        return await client_1.prisma.task.delete({
            where: { id },
        });
    }
}
exports.TasksService = TasksService;
//# sourceMappingURL=tasks.service.js.map