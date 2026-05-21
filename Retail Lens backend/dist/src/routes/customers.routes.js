"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.customersRouter = void 0;
const express_1 = require("express");
const customers_controller_1 = require("../controllers/customers.controller");
exports.customersRouter = (0, express_1.Router)();
exports.customersRouter.get('/', customers_controller_1.CustomersController.getCustomers);
exports.customersRouter.post('/', customers_controller_1.CustomersController.createCustomer);
exports.customersRouter.patch('/:id', customers_controller_1.CustomersController.updateCustomer);
exports.customersRouter.delete('/:id', customers_controller_1.CustomersController.deleteCustomer);
//# sourceMappingURL=customers.routes.js.map