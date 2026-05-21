import { prisma } from '../prisma/client';
import { TaskStatus, Priority } from '@prisma/client';

export class TasksService {
  static async getAllTasks() {
    return await prisma.task.findMany({
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

  static async createTask(data: {
    title: string;
    description?: string;
    assignedToId: string;
    status?: TaskStatus;
    priority?: Priority;
    dueDate?: string;
  }) {
    // Validate employee existence (try ID first, then Name)
    let employee = await prisma.employee.findUnique({
      where: { id: data.assignedToId },
    });

    if (!employee) {
      employee = await prisma.employee.findFirst({
        where: { name: data.assignedToId },
      });
    }

    if (!employee) {
      throw new Error('Assigned employee not found');
    }

    return await prisma.task.create({
      data: {
        title: data.title,
        description: data.description,
        assignedToId: employee.id, // Use the actual employee ID
        status: data.status || TaskStatus.PENDING,
        priority: data.priority || Priority.MEDIUM,
        dueDate: data.dueDate,
      },
    });
  }

  static async updateTaskStatus(id: string, status: TaskStatus) {
    const task = await prisma.task.findUnique({
      where: { id },
    });

    if (!task) {
      const error = new Error('Task not found');
      (error as any).code = 'P2025'; // Simulating Prisma not found code for controller compatibility
      throw error;
    }

    return await prisma.task.update({
      where: { id },
      data: { status },
    });
  }

  static async updateTask(id: string, data: {
    title?: string;
    description?: string;
    assignedToId?: string;
    status?: TaskStatus;
    priority?: Priority;
    dueDate?: string;
  }) {
    const task = await prisma.task.findUnique({
      where: { id },
    });

    if (!task) {
      const error = new Error('Task not found');
      (error as any).code = 'P2025';
      throw error;
    }

    let employeeId = data.assignedToId;
    if (employeeId) {
      let employee = await prisma.employee.findUnique({
        where: { id: employeeId },
      });

      if (!employee) {
        employee = await prisma.employee.findFirst({
          where: { name: employeeId },
        });
      }

      if (!employee) {
        throw new Error('Assigned employee not found');
      }
      employeeId = employee.id;
    }

    return await prisma.task.update({
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

  static async deleteTask(id: string) {
    const task = await prisma.task.findUnique({
      where: { id },
    });

    if (!task) {
      const error = new Error('Task not found');
      (error as any).code = 'P2025';
      throw error;
    }

    return await prisma.task.delete({
      where: { id },
    });
  }
}
