import { Request, Response } from 'express';
export declare class VendorsController {
    static getVendors(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static createVendor(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static getVendorById(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static getVendorLedger(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static deleteVendor(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static payVendor(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static updateVendor(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
}
