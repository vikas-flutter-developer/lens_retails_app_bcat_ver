import { Router } from 'express';
import { authRouter } from './auth.routes';
import { employeesRouter } from './employees.routes';
import { financeRouter } from './finance.routes';
import { healthRouter } from './health.routes';
import { inventoryRouter } from './inventory.routes';
import { jobCardsRouter } from './job-cards.routes';
import { notificationsRouter } from './notifications.routes';
import { reportsRouter } from './reports.routes';
import { settingsRouter } from './settings.routes';
import { syncRouter } from './sync.routes';
import { tasksRouter } from './tasks.routes';

export const apiV1Router = Router();

apiV1Router.use('/auth', authRouter);
apiV1Router.use('/job-cards', jobCardsRouter);
apiV1Router.use('/inventory', inventoryRouter);
apiV1Router.use('/tasks', tasksRouter);
apiV1Router.use('/employees', employeesRouter);
apiV1Router.use('/reports', reportsRouter);
apiV1Router.use('/finances', financeRouter);
apiV1Router.use('/settings', settingsRouter);
apiV1Router.use('/notifications', notificationsRouter);
apiV1Router.use('/sync', syncRouter);
apiV1Router.use('/health', healthRouter);
