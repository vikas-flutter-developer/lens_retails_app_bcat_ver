import { Request, Response } from 'express';
import { prisma } from '../prisma/client';
import { sendSuccess, sendError } from '../utils/response.util';

export class CustomersController {
  static async getCustomers(req: Request, res: Response) {
    try {
      const customers = await prisma.customer.findMany({
        orderBy: { fullName: 'asc' },
      });
      return sendSuccess(res, { data: customers }, 'Customers fetched successfully');
    } catch (error: any) {
      console.error('Error fetching customers:', error);
      return sendError(res, error.message || 'Failed to fetch customers');
    }
  }

  static async createCustomer(req: Request, res: Response) {
    try {
      const { id, fullName, phone, email, dob, address } = req.body;

      if (!fullName || !phone) {
        return sendError(res, 'fullName and phone are required', 400);
      }

      const customer = await prisma.customer.create({
        data: {
          id: id || undefined,
          fullName,
          phone,
          email: email || null,
          dob: dob || null,
          address: address || null,
        },
      });

      return sendSuccess(res, { data: customer }, 'Customer created successfully', 201);
    } catch (error: any) {
      console.error('Error creating customer:', error);
      if (error.code === 'P2002') {
        return sendError(res, 'Customer with this phone number already exists', 400);
      }
      return sendError(res, error.message || 'Failed to create customer');
    }
  }

  static async updateCustomer(req: Request, res: Response) {
    try {
      const id = req.params.id as string;
      const { fullName, phone, email, dob, address } = req.body;

      const customer = await prisma.customer.update({
        where: { id },
        data: {
          fullName: fullName || undefined,
          phone: phone || undefined,
          email: email !== undefined ? email : undefined,
          dob: dob !== undefined ? dob : undefined,
          address: address !== undefined ? address : undefined,
        },
      });

      return sendSuccess(res, { data: customer }, 'Customer updated successfully');
    } catch (error: any) {
      console.error('Error updating customer:', error);
      if (error.code === 'P2025') {
        return sendError(res, 'Customer not found', 404);
      }
      return sendError(res, error.message || 'Failed to update customer');
    }
  }

  static async deleteCustomer(req: Request, res: Response) {
    try {
      const id = req.params.id as string;

      // Safe Cascade delete: Delete associated Job Card transactions first to prevent Foreign Key errors
      const jobCards = await prisma.jobCard.findMany({ where: { customerId: id } });
      const jobCardIds = jobCards.map((jc) => jc.id);

      if (jobCardIds.length > 0) {
        await prisma.payment.deleteMany({ where: { jobCardId: { in: jobCardIds } } });
        await prisma.jobCardItem.deleteMany({ where: { jobCardId: { in: jobCardIds } } });
        await prisma.jobCard.deleteMany({ where: { customerId: id } });
      }

      await prisma.customer.delete({
        where: { id },
      });

      return sendSuccess(res, {}, 'Customer deleted successfully');
    } catch (error: any) {
      console.error('Error deleting customer:', error);
      if (error.code === 'P2025') {
        return sendError(res, 'Customer not found', 404);
      }
      return sendError(res, error.message || 'Failed to delete customer');
    }
  }
}
