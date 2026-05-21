import { Router } from 'express';
import { CustomersController } from '../controllers/customers.controller';

export const customersRouter = Router();

customersRouter.get('/', CustomersController.getCustomers);
customersRouter.post('/', CustomersController.createCustomer);
customersRouter.patch('/:id', CustomersController.updateCustomer);
customersRouter.delete('/:id', CustomersController.deleteCustomer);
