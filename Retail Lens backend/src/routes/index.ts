import { Router } from 'express';
import { authRouter } from './auth.routes';
import { employeesRouter } from './employees.routes';
import { expensesRouter } from './expenses.routes';
import { financeRouter } from './finance.routes';
import { healthRouter } from './health.routes';
import { inventoryRouter } from './inventory.routes';
import { jobCardsRouter } from './job-cards.routes';
import { notificationsRouter } from './notifications.routes';
import { reportsRouter } from './reports.routes';
import { settingsRouter } from './settings.routes';
import { syncRouter } from './sync.routes';
import { tasksRouter } from './tasks.routes';
import { vendorsRouter } from './vendors.routes';
import { mobileAnalyticsRouter } from './mobile-analytics.routes';
import { ordersRouter } from './orders.routes';
import { paymentRouter } from './payment.routes';
import { customersRouter } from './customers.routes';
import { productsRouter } from './products.routes';
import { rfidRouter } from './rfid.routes';


export const apiV1Router = Router();

apiV1Router.use('/auth', authRouter);
apiV1Router.use('/payment', paymentRouter);
apiV1Router.use('/job-cards', jobCardsRouter);
apiV1Router.use('/customers', customersRouter);
apiV1Router.use('/products', productsRouter);
apiV1Router.use('/rfid', rfidRouter);

apiV1Router.use('/inventory', inventoryRouter);
apiV1Router.use('/expenses', expensesRouter);
apiV1Router.use('/vendors', vendorsRouter);
apiV1Router.use('/tasks', tasksRouter);
apiV1Router.use('/employees', employeesRouter);
apiV1Router.use('/reports', reportsRouter);
apiV1Router.use('/finances', financeRouter);
apiV1Router.use('/settings', settingsRouter);
apiV1Router.use('/notifications', notificationsRouter);
apiV1Router.use('/sync', syncRouter);
apiV1Router.use('/health', healthRouter);
apiV1Router.use('/mobile', mobileAnalyticsRouter);
apiV1Router.use('/orders', ordersRouter);


