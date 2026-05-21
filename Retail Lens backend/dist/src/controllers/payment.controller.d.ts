import { Request, Response } from 'express';
export declare class PaymentController {
    static createOrder(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static verifyPaymentAndRegister(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static getAllOwners(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
}
