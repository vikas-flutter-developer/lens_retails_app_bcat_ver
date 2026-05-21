import { Request, Response } from 'express';
export declare class TasksController {
    static getTasks(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static createTask(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static updateTaskStatus(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static updateTask(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static deleteTask(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
}
