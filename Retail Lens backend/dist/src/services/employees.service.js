"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.EmployeesService = void 0;
const client_1 = require("../prisma/client");
class EmployeesService {
    static async getAllEmployees() {
        return await client_1.prisma.employee.findMany({
            where: {
                NOT: {
                    role: {
                        equals: 'OWNER',
                        mode: 'insensitive',
                    },
                },
            },
            orderBy: {
                name: 'asc',
            },
        });
    }
    static async createEmployee(data) {
        return await client_1.prisma.employee.create({
            data: {
                name: data.name,
                role: data.role,
                phone: data.phone,
                status: data.status || 'Active',
            },
        });
    }
    static async deleteEmployee(id) {
        return await client_1.prisma.employee.delete({
            where: { id },
        });
    }
    static async updateEmployee(id, data) {
        const employee = await client_1.prisma.employee.findUnique({
            where: { id },
        });
        if (!employee) {
            const error = new Error('Employee not found');
            error.code = 'P2025';
            throw error;
        }
        return await client_1.prisma.employee.update({
            where: { id },
            data: {
                name: data.name !== undefined ? data.name : employee.name,
                role: data.role !== undefined ? data.role : employee.role,
                phone: data.phone !== undefined ? data.phone : employee.phone,
                status: data.status !== undefined ? data.status : employee.status,
            },
        });
    }
    static async getEmployeesForTasks() {
        return await client_1.prisma.employee.findMany({
            where: {
                status: 'Active',
                NOT: {
                    role: {
                        equals: 'OWNER',
                        mode: 'insensitive',
                    },
                },
            },
            select: {
                id: true,
                name: true,
            },
            orderBy: {
                name: 'asc',
            },
        });
    }
    static async getEmployeeTaskCounts(id) {
        const employee = await client_1.prisma.employee.findUnique({
            where: { id },
        });
        if (!employee) {
            throw new Error('Employee not found');
        }
        const tasks = await client_1.prisma.task.findMany({
            where: { assignedToId: id },
            select: { status: true },
        });
        const assigned = tasks.length;
        const completed = tasks.filter((t) => t.status === 'COMPLETED').length;
        const pending = tasks.filter((t) => t.status === 'PENDING').length;
        return {
            employeeId: id,
            assigned,
            completed,
            pending,
        };
    }
}
exports.EmployeesService = EmployeesService;
//# sourceMappingURL=employees.service.js.map