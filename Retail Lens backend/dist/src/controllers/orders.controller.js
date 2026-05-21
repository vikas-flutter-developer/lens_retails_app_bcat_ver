"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.OrdersController = void 0;
const orders_service_1 = require("../services/orders.service");
const response_util_1 = require("../utils/response.util");
class OrdersController {
    static async getOrders(req, res) {
        try {
            const data = await orders_service_1.OrdersService.getAllOrders();
            return (0, response_util_1.sendSuccess)(res, { data }, 'Orders fetched successfully');
        }
        catch (error) {
            console.error('Error fetching orders:', error);
            return (0, response_util_1.sendError)(res, error.message || 'Failed to fetch orders');
        }
    }
    static async createOrder(req, res) {
        try {
            const order = await orders_service_1.OrdersService.createOrder(req.body);
            return (0, response_util_1.sendSuccess)(res, { data: order }, 'Order created successfully', 201);
        }
        catch (error) {
            console.error('Error creating order:', error);
            return (0, response_util_1.sendError)(res, error.message || 'Failed to create order');
        }
    }
    static async updateOrder(req, res) {
        try {
            const { id } = req.params;
            const order = await orders_service_1.OrdersService.updateOrder(id, req.body);
            return (0, response_util_1.sendSuccess)(res, { data: order }, 'Order updated successfully');
        }
        catch (error) {
            console.error('Error updating order:', error);
            return (0, response_util_1.sendError)(res, error.message || 'Failed to update order');
        }
    }
}
exports.OrdersController = OrdersController;
//# sourceMappingURL=orders.controller.js.map