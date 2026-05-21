"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.EmployeesController = void 0;
const employees_service_1 = require("../services/employees.service");
const response_util_1 = require("../utils/response.util");
class EmployeesController {
    static async getEmployees(req, res) {
        try {
            const employees = await employees_service_1.EmployeesService.getAllEmployees();
            const data = employees.map(emp => ({
                id: emp.id,
                name: emp.name,
                role: emp.role,
                phone: emp.phone || '',
                status: emp.status
            }));
            return (0, response_util_1.sendSuccess)(res, { data }, 'Employees fetched successfully');
        }
        catch (error) {
            console.error('Error fetching employees:', error);
            return (0, response_util_1.sendError)(res, error.message || 'Failed to fetch employees');
        }
    }
    static async createEmployee(req, res) {
        try {
            const { name, role, phone, status } = req.body;
            if (!name || !role) {
                return (0, response_util_1.sendError)(res, 'Name and role are required', 400);
            }
            const employee = await employees_service_1.EmployeesService.createEmployee({
                name,
                role,
                phone,
                status
            });
            return (0, response_util_1.sendSuccess)(res, {
                data: {
                    id: employee.id,
                    name: employee.name,
                    role: employee.role
                }
            }, 'Employee registered successfully', 201);
        }
        catch (error) {
            console.error('Error creating employee:', error);
            return (0, response_util_1.sendError)(res, error.message || 'Failed to register employee');
        }
    }
    static async deleteEmployee(req, res) {
        try {
            const { id } = req.params;
            await employees_service_1.EmployeesService.deleteEmployee(id);
            return (0, response_util_1.sendSuccess)(res, {}, 'Employee record removed successfully');
        }
        catch (error) {
            console.error('Error deleting employee:', error);
            if (error.code === 'P2025') {
                return (0, response_util_1.sendError)(res, 'Employee not found', 404);
            }
            return (0, response_util_1.sendError)(res, error.message || 'Failed to remove employee record');
        }
    }
    static async getEmployeesForTasks(req, res) {
        try {
            const employees = await employees_service_1.EmployeesService.getEmployeesForTasks();
            return (0, response_util_1.sendSuccess)(res, { data: employees }, 'Employees for tasks fetched successfully');
        }
        catch (error) {
            console.error('Error fetching employees for tasks:', error);
            return (0, response_util_1.sendError)(res, error.message || 'Failed to fetch employees for tasks');
        }
    }
    static async getEmployeeTaskCounts(req, res) {
        try {
            const { id } = req.params;
            const counts = await employees_service_1.EmployeesService.getEmployeeTaskCounts(id);
            return (0, response_util_1.sendSuccess)(res, counts, 'Employee task counts fetched successfully');
        }
        catch (error) {
            console.error('Error fetching employee task counts:', error);
            if (error.message === 'Employee not found') {
                return (0, response_util_1.sendError)(res, error.message, 404);
            }
            return (0, response_util_1.sendError)(res, error.message || 'Failed to fetch employee task counts');
        }
    }
    static async updateEmployee(req, res) {
        try {
            const { id } = req.params;
            const { name, role, phone, status } = req.body;
            const employee = await employees_service_1.EmployeesService.updateEmployee(id, {
                name,
                role,
                phone,
                status
            });
            return (0, response_util_1.sendSuccess)(res, {
                data: {
                    id: employee.id,
                    name: employee.name,
                    role: employee.role,
                    phone: employee.phone,
                    status: employee.status
                }
            }, 'Employee record updated successfully');
        }
        catch (error) {
            console.error('Error updating employee:', error);
            if (error.code === 'P2025' || error.message === 'Employee not found') {
                return (0, response_util_1.sendError)(res, 'Employee not found', 404);
            }
            return (0, response_util_1.sendError)(res, error.message || 'Failed to update employee record');
        }
    }
}
exports.EmployeesController = EmployeesController;
//# sourceMappingURL=employees.controller.js.map