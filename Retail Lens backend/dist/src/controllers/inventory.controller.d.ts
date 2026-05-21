import { Request, Response } from 'express';
export declare class InventoryController {
    static getInventory(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static createInventory(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static updateInventory(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static getAlerts(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static getMovementHistory(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static scanUpdate(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static getFIFOBatches(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static registerUnits(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static getMaxSerial(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
}
