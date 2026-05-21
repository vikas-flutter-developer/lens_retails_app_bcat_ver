import { EmployeesService } from './employees.service';
export declare class EmployeesController {
    private readonly employeesService;
    constructor(employeesService: EmployeesService);
    getTaskReport(id: string): {
        employeeId: string;
        assigned: number;
        completed: number;
        pending: number;
    };
}
