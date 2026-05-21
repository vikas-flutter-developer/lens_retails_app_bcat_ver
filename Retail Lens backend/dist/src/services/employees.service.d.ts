export declare class EmployeesService {
    static getAllEmployees(): Promise<{
        id: string;
        name: string;
        createdAt: Date;
        updatedAt: Date;
        userId: string | null;
        status: string;
        role: string;
        phone: string | null;
    }[]>;
    static createEmployee(data: {
        name: string;
        role: string;
        phone?: string;
        status?: string;
    }): Promise<{
        id: string;
        name: string;
        createdAt: Date;
        updatedAt: Date;
        userId: string | null;
        status: string;
        role: string;
        phone: string | null;
    }>;
    static deleteEmployee(id: string): Promise<{
        id: string;
        name: string;
        createdAt: Date;
        updatedAt: Date;
        userId: string | null;
        status: string;
        role: string;
        phone: string | null;
    }>;
    static updateEmployee(id: string, data: {
        name?: string;
        role?: string;
        phone?: string;
        status?: string;
    }): Promise<{
        id: string;
        name: string;
        createdAt: Date;
        updatedAt: Date;
        userId: string | null;
        status: string;
        role: string;
        phone: string | null;
    }>;
    static getEmployeesForTasks(): Promise<{
        id: string;
        name: string;
    }[]>;
    static getEmployeeTaskCounts(id: string): Promise<{
        employeeId: string;
        assigned: number;
        completed: number;
        pending: number;
    }>;
}
