import { Request, Response } from 'express';
export declare class EmployeesController {
    static getEmployees(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static createEmployee(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static deleteEmployee(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static getEmployeesForTasks(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static getEmployeeTaskCounts(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static updateEmployee(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
}
