"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CustomersController = void 0;
const client_1 = require("../prisma/client");
const response_util_1 = require("../utils/response.util");
class CustomersController {
    static async getCustomers(req, res) {
        try {
            const customers = await client_1.prisma.customer.findMany({
                orderBy: { fullName: 'asc' },
            });
            return (0, response_util_1.sendSuccess)(res, { data: customers }, 'Customers fetched successfully');
        }
        catch (error) {
            console.error('Error fetching customers:', error);
            return (0, response_util_1.sendError)(res, error.message || 'Failed to fetch customers');
        }
    }
    static async createCustomer(req, res) {
        try {
            const { id, fullName, phone, email, dob, address } = req.body;
            if (!fullName || !phone) {
                return (0, response_util_1.sendError)(res, 'fullName and phone are required', 400);
            }
            const customer = await client_1.prisma.customer.create({
                data: {
                    id: id || undefined,
                    fullName,
                    phone,
                    email: email || null,
                    dob: dob || null,
                    address: address || null,
                },
            });
            return (0, response_util_1.sendSuccess)(res, { data: customer }, 'Customer created successfully', 201);
        }
        catch (error) {
            console.error('Error creating customer:', error);
            if (error.code === 'P2002') {
                return (0, response_util_1.sendError)(res, 'Customer with this phone number already exists', 400);
            }
            return (0, response_util_1.sendError)(res, error.message || 'Failed to create customer');
        }
    }
    static async updateCustomer(req, res) {
        try {
            const id = req.params.id;
            const { fullName, phone, email, dob, address } = req.body;
            const customer = await client_1.prisma.customer.update({
                where: { id },
                data: {
                    fullName: fullName || undefined,
                    phone: phone || undefined,
                    email: email !== undefined ? email : undefined,
                    dob: dob !== undefined ? dob : undefined,
                    address: address !== undefined ? address : undefined,
                },
            });
            return (0, response_util_1.sendSuccess)(res, { data: customer }, 'Customer updated successfully');
        }
        catch (error) {
            console.error('Error updating customer:', error);
            if (error.code === 'P2025') {
                return (0, response_util_1.sendError)(res, 'Customer not found', 404);
            }
            return (0, response_util_1.sendError)(res, error.message || 'Failed to update customer');
        }
    }
    static async deleteCustomer(req, res) {
        try {
            const id = req.params.id;
            const jobCards = await client_1.prisma.jobCard.findMany({ where: { customerId: id } });
            const jobCardIds = jobCards.map((jc) => jc.id);
            if (jobCardIds.length > 0) {
                await client_1.prisma.payment.deleteMany({ where: { jobCardId: { in: jobCardIds } } });
                await client_1.prisma.jobCardItem.deleteMany({ where: { jobCardId: { in: jobCardIds } } });
                await client_1.prisma.jobCard.deleteMany({ where: { customerId: id } });
            }
            await client_1.prisma.customer.delete({
                where: { id },
            });
            return (0, response_util_1.sendSuccess)(res, {}, 'Customer deleted successfully');
        }
        catch (error) {
            console.error('Error deleting customer:', error);
            if (error.code === 'P2025') {
                return (0, response_util_1.sendError)(res, 'Customer not found', 404);
            }
            return (0, response_util_1.sendError)(res, error.message || 'Failed to delete customer');
        }
    }
}
exports.CustomersController = CustomersController;
//# sourceMappingURL=customers.controller.js.map