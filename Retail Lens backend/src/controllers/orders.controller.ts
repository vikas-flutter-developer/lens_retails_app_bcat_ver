import { Request, Response } from 'express';
import { OrdersService } from '../services/orders.service';
import { sendSuccess, sendError } from '../utils/response.util';

export class OrdersController {
  static async getOrders(req: Request, res: Response) {
    try {
      const data = await OrdersService.getAllOrders();
      return sendSuccess(res, { data }, 'Orders fetched successfully');
    } catch (error: any) {
      console.error('Error fetching orders:', error);
      return sendError(res, error.message || 'Failed to fetch orders');
    }
  }

  static async createOrder(req: Request, res: Response) {
    try {
      const order = await OrdersService.createOrder(req.body);
      return sendSuccess(res, { data: order }, 'Order created successfully', 201);
    } catch (error: any) {
      console.error('Error creating order:', error);
      return sendError(res, error.message || 'Failed to create order');
    }
  }

  static async updateOrder(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const order = await OrdersService.updateOrder(id as string, req.body);
      return sendSuccess(res, { data: order }, 'Order updated successfully');
    } catch (error: any) {
      console.error('Error updating order:', error);
      return sendError(res, error.message || 'Failed to update order');
    }
  }
}
