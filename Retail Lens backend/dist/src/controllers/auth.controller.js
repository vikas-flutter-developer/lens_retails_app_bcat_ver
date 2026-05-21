"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthController = void 0;
const auth_service_1 = require("../services/auth.service");
const response_util_1 = require("../utils/response.util");
const client_1 = require("@prisma/client");
class AuthController {
    static async register(req, res) {
        try {
            const { fullName, email, password, role: bodyRole } = req.body;
            const role = bodyRole || client_1.UserRole.STAFF;
            if (!fullName || !email || !password) {
                return (0, response_util_1.sendError)(res, 'Missing required fields', 400);
            }
            if (bodyRole && !Object.values(client_1.UserRole).includes(bodyRole)) {
                return (0, response_util_1.sendError)(res, 'Invalid role', 400);
            }
            const user = await auth_service_1.AuthService.register({ fullName, email, password, role });
            return (0, response_util_1.sendSuccess)(res, { data: user }, 'User registered successfully', 201);
        }
        catch (error) {
            if (error.message === 'Email already in use') {
                return (0, response_util_1.sendError)(res, error.message, 409);
            }
            return (0, response_util_1.sendError)(res, error.message || 'Registration failed');
        }
    }
    static async login(req, res) {
        try {
            const { email, password } = req.body;
            if (!email || !password) {
                return (0, response_util_1.sendError)(res, 'Email and password are required', 400);
            }
            const result = await auth_service_1.AuthService.login({ email, password });
            return (0, response_util_1.sendSuccess)(res, result, 'Login successful');
        }
        catch (error) {
            if (error.message === 'Invalid credentials') {
                return (0, response_util_1.sendError)(res, error.message, 401);
            }
            return (0, response_util_1.sendError)(res, error.message || 'Login failed');
        }
    }
    static async refresh(req, res) {
        try {
            const { refreshToken } = req.body;
            if (!refreshToken) {
                return (0, response_util_1.sendError)(res, 'Refresh token is required', 400);
            }
            const result = await auth_service_1.AuthService.refresh(refreshToken);
            return (0, response_util_1.sendSuccess)(res, result, 'Token refreshed successfully');
        }
        catch (error) {
            return (0, response_util_1.sendError)(res, error.message, 401);
        }
    }
    static async logout(req, res) {
        try {
            const { refreshToken } = req.body;
            if (!refreshToken) {
                return (0, response_util_1.sendError)(res, 'Refresh token is required', 400);
            }
            await auth_service_1.AuthService.logout(refreshToken);
            return (0, response_util_1.sendSuccess)(res, null, 'Logged out successfully');
        }
        catch (error) {
            return (0, response_util_1.sendError)(res, error.message || 'Logout failed');
        }
    }
    static async forgotPassword(req, res) {
        try {
            const { email } = req.body;
            if (!email) {
                return (0, response_util_1.sendError)(res, 'Email is required', 400);
            }
            const result = await auth_service_1.AuthService.forgotPassword(email);
            return (0, response_util_1.sendSuccess)(res, result, 'Reset link sent to email');
        }
        catch (error) {
            return (0, response_util_1.sendError)(res, error.message || 'Failed to process request');
        }
    }
    static async resetPassword(req, res) {
        try {
            const { token, newPassword } = req.body;
            if (!token || !newPassword) {
                return (0, response_util_1.sendError)(res, 'Token and new password are required', 400);
            }
            await auth_service_1.AuthService.resetPassword(token, newPassword);
            return (0, response_util_1.sendSuccess)(res, null, 'Password reset successful');
        }
        catch (error) {
            return (0, response_util_1.sendError)(res, error.message || 'Password reset failed', 400);
        }
    }
}
exports.AuthController = AuthController;
//# sourceMappingURL=auth.controller.js.map