import { Request, Response } from 'express';
import { EmployeesService } from '../services/employees.service';
import { sendSuccess, sendError } from '../utils/response.util';

export class EmployeesController {
  static async getEmployees(req: Request, res: Response) {
    try {
      const employees = await EmployeesService.getAllEmployees();
      
      const data = employees.map(emp => ({
        id: emp.id,
        name: emp.name,
        role: emp.role,
        phone: emp.phone || '',
        status: emp.status
      }));

      return sendSuccess(res, { data }, 'Employees fetched successfully');
    } catch (error: any) {
      console.error('Error fetching employees:', error);
      return sendError(res, error.message || 'Failed to fetch employees');
    }
  }

  static async createEmployee(req: Request, res: Response) {
    try {
      const { name, role, phone, status } = req.body;

      if (!name || !role) {
        return sendError(res, 'Name and role are required', 400);
      }

      const employee = await EmployeesService.createEmployee({
        name,
        role,
        phone,
        status
      });

      return sendSuccess(
        res,
        { 
          data: {
            id: employee.id,
            name: employee.name,
            role: employee.role
          } 
        },
        'Employee registered successfully',
        201
      );
    } catch (error: any) {
      console.error('Error creating employee:', error);
      return sendError(res, error.message || 'Failed to register employee');
    }
  }

  static async deleteEmployee(req: Request, res: Response) {
    try {
      const { id } = req.params;
      await EmployeesService.deleteEmployee(id as string);
      return sendSuccess(res, {}, 'Employee record removed successfully');
    } catch (error: any) {
      console.error('Error deleting employee:', error);
      if (error.code === 'P2025') {
        return sendError(res, 'Employee not found', 404);
      }
      return sendError(res, error.message || 'Failed to remove employee record');
    }
  }

  static async getEmployeesForTasks(req: Request, res: Response) {
    try {
      const employees = await EmployeesService.getEmployeesForTasks();
      return sendSuccess(res, { data: employees }, 'Employees for tasks fetched successfully');
    } catch (error: any) {
      console.error('Error fetching employees for tasks:', error);
      return sendError(res, error.message || 'Failed to fetch employees for tasks');
    }
  }

  static async getEmployeeTaskCounts(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const counts = await EmployeesService.getEmployeeTaskCounts(id as string);
      return sendSuccess(res, counts, 'Employee task counts fetched successfully');
    } catch (error: any) {
      console.error('Error fetching employee task counts:', error);
      if (error.message === 'Employee not found') {
        return sendError(res, error.message, 404);
      }
      return sendError(res, error.message || 'Failed to fetch employee task counts');
    }
  }

  static async updateEmployee(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const { name, role, phone, status } = req.body;

      const employee = await EmployeesService.updateEmployee(id as string, {
        name,
        role,
        phone,
        status
      });

      return sendSuccess(
        res,
        {
          data: {
            id: employee.id,
            name: employee.name,
            role: employee.role,
            phone: employee.phone,
            status: employee.status
          }
        },
        'Employee record updated successfully'
      );
    } catch (error: any) {
      console.error('Error updating employee:', error);
      if (error.code === 'P2025' || error.message === 'Employee not found') {
        return sendError(res, 'Employee not found', 404);
      }
      return sendError(res, error.message || 'Failed to update employee record');
    }
  }
}
