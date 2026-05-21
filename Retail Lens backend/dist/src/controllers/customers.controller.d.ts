import { Request, Response } from 'express';
export declare class CustomersController {
    static getCustomers(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static createCustomer(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static updateCustomer(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static deleteCustomer(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
}
