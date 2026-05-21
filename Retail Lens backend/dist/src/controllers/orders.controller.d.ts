import { Request, Response } from 'express';
export declare class OrdersController {
    static getOrders(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static createOrder(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static updateOrder(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
}
