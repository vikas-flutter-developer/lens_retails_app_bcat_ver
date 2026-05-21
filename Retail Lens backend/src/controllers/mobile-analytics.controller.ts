import { Request, Response } from 'express';
import { MobileAnalyticsService } from '../services/mobile-analytics.service';
import { sendSuccess, sendError } from '../utils/response.util';

export class MobileAnalyticsController {
  static async getDashboard(req: Request, res: Response) {
    try {
      const data = await MobileAnalyticsService.getDashboardData();
      return sendSuccess(res, { data }, 'Dashboard data fetched successfully');
    } catch (error: any) {
      console.error('Error fetching dashboard analytics:', error);
      return sendError(res, error.message || 'Failed to fetch dashboard data');
    }
  }
}
