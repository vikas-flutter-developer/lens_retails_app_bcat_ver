import { Request, Response } from 'express';
export declare class RfidController {
    static runBatchAudit(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static smartCheckout(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static locateItem(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static triggerGateAlarm(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static verifyShipment(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
}
