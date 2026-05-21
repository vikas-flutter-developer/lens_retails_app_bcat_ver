import { prisma } from '../prisma/client';

export class EmployeesService {
  static async getAllEmployees() {
    return await prisma.employee.findMany({
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

  static async createEmployee(data: {
    name: string;
    role: string;
    phone?: string;
    status?: string;
  }) {
    return await prisma.employee.create({
      data: {
        name: data.name,
        role: data.role,
        phone: data.phone,
        status: data.status || 'Active',
      },
    });
  }

  static async deleteEmployee(id: string) {
    return await prisma.employee.delete({
      where: { id },
    });
  }

  static async updateEmployee(id: string, data: {
    name?: string;
    role?: string;
    phone?: string;
    status?: string;
  }) {
    const employee = await prisma.employee.findUnique({
      where: { id },
    });

    if (!employee) {
      const error = new Error('Employee not found');
      (error as any).code = 'P2025';
      throw error;
    }

    return await prisma.employee.update({
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
    return await prisma.employee.findMany({
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

  static async getEmployeeTaskCounts(id: string) {
    const employee = await prisma.employee.findUnique({
      where: { id },
    });

    if (!employee) {
      throw new Error('Employee not found');
    }

    const tasks = await prisma.task.findMany({
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
