import { Request, Response } from 'express';
export declare class ProductsController {
    static getProductByQr(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
}
