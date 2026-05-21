export declare class EmployeesService {
    getTaskReport(id: string): {
        employeeId: string;
        assigned: number;
        completed: number;
        pending: number;
    };
}
