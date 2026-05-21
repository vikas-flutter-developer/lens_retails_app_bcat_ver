import { Router } from 'express';
import { MobileAnalyticsController } from '../controllers/mobile-analytics.controller';

export const mobileAnalyticsRouter = Router();

mobileAnalyticsRouter.get('/analytics/dashboard', MobileAnalyticsController.getDashboard);
