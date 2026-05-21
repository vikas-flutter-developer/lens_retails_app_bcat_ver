import { Response } from 'express';
export interface ApiResponse<T = any> {
    success: boolean;
    message?: string;
    data?: T;
    token?: string;
    refreshToken?: string;
    user?: any;
    errors?: any;
}
export declare const sendSuccess: (res: Response, data: any, message?: string, statusCode?: number) => Response<any, Record<string, any>>;
export declare const sendError: (res: Response, message?: string, statusCode?: number, errors?: any) => Response<any, Record<string, any>>;
