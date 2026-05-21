import { TaskStatus, Priority } from '@prisma/client';
export declare class TasksService {
    static getAllTasks(): Promise<({
        assignedTo: {
            id: string;
            name: string;
        } | null;
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        status: import("@prisma/client").$Enums.TaskStatus;
        title: string;
        priority: import("@prisma/client").$Enums.Priority;
        description: string | null;
        dueDate: string | null;
        assignedToId: string | null;
    })[]>;
    static createTask(data: {
        title: string;
        description?: string;
        assignedToId: string;
        status?: TaskStatus;
        priority?: Priority;
        dueDate?: string;
    }): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        status: import("@prisma/client").$Enums.TaskStatus;
        title: string;
        priority: import("@prisma/client").$Enums.Priority;
        description: string | null;
        dueDate: string | null;
        assignedToId: string | null;
    }>;
    static updateTaskStatus(id: string, status: TaskStatus): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        status: import("@prisma/client").$Enums.TaskStatus;
        title: string;
        priority: import("@prisma/client").$Enums.Priority;
        description: string | null;
        dueDate: string | null;
        assignedToId: string | null;
    }>;
    static updateTask(id: string, data: {
        title?: string;
        description?: string;
        assignedToId?: string;
        status?: TaskStatus;
        priority?: Priority;
        dueDate?: string;
    }): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        status: import("@prisma/client").$Enums.TaskStatus;
        title: string;
        priority: import("@prisma/client").$Enums.Priority;
        description: string | null;
        dueDate: string | null;
        assignedToId: string | null;
    }>;
    static deleteTask(id: string): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        status: import("@prisma/client").$Enums.TaskStatus;
        title: string;
        priority: import("@prisma/client").$Enums.Priority;
        description: string | null;
        dueDate: string | null;
        assignedToId: string | null;
    }>;
}
