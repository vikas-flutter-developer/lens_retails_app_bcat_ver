"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthService = void 0;
const bcrypt_1 = __importDefault(require("bcrypt"));
const crypto_1 = __importDefault(require("crypto"));
const client_1 = require("../prisma/client");
const jwt_util_1 = require("../utils/jwt.util");
class AuthService {
    static async register(data) {
        const existingUser = await client_1.prisma.user.findUnique({
            where: { email: data.email },
        });
        if (existingUser) {
            throw new Error('Email already in use');
        }
        const passwordHash = await bcrypt_1.default.hash(data.password, 10);
        const user = await client_1.prisma.user.create({
            data: {
                fullName: data.fullName,
                email: data.email,
                passwordHash,
                role: data.role,
                subscriptionPlan: data.subscriptionPlan || null,
                subscriptionExpiresAt: data.subscriptionExpiresAt || null,
            },
            select: {
                id: true,
                fullName: true,
                email: true,
                role: true,
                subscriptionPlan: true,
                subscriptionExpiresAt: true,
                createdAt: true,
            },
        });
        return user;
    }
    static async login(data) {
        const user = await client_1.prisma.user.findUnique({
            where: { email: data.email },
        });
        if (!user) {
            throw new Error('Invalid credentials');
        }
        const isPasswordValid = await bcrypt_1.default.compare(data.password, user.passwordHash);
        if (!isPasswordValid) {
            throw new Error('Invalid credentials');
        }
        const payload = { userId: user.id, role: user.role };
        const accessToken = (0, jwt_util_1.generateAccessToken)(payload);
        const refreshToken = (0, jwt_util_1.generateRefreshToken)(payload);
        await client_1.prisma.refreshToken.create({
            data: {
                token: refreshToken,
                userId: user.id,
                expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
            },
        });
        return {
            token: accessToken,
            refreshToken,
            user: {
                id: user.id,
                fullName: user.fullName,
                email: user.email,
                role: user.role,
                subscriptionPlan: user.subscriptionPlan,
                subscriptionExpiresAt: user.subscriptionExpiresAt,
            },
        };
    }
    static async refresh(token) {
        try {
            const storedToken = await client_1.prisma.refreshToken.findUnique({
                where: { token },
            });
            if (!storedToken || storedToken.expiresAt < new Date()) {
                if (storedToken) {
                    await client_1.prisma.refreshToken.delete({ where: { id: storedToken.id } });
                }
                throw new Error('Invalid or expired refresh token');
            }
            const decoded = (0, jwt_util_1.verifyRefreshToken)(token);
            const newAccessToken = (0, jwt_util_1.generateAccessToken)({ userId: decoded.userId, role: decoded.role });
            return { token: newAccessToken };
        }
        catch (error) {
            throw new Error('Invalid or expired refresh token');
        }
    }
    static async logout(refreshToken) {
        try {
            await client_1.prisma.refreshToken.delete({
                where: { token: refreshToken },
            });
        }
        catch (error) {
        }
    }
    static async forgotPassword(email) {
        const user = await client_1.prisma.user.findUnique({ where: { email } });
        if (!user) {
            throw new Error('This email address is not registered with us.');
        }
        const resetToken = crypto_1.default.randomBytes(32).toString('hex');
        const resetExpires = new Date(Date.now() + 3600000);
        await client_1.prisma.user.update({
            where: { id: user.id },
            data: {
                passwordResetToken: resetToken,
                passwordResetExpires: resetExpires,
            },
        });
        return { resetToken };
    }
    static async resetPassword(token, newPassword) {
        const user = await client_1.prisma.user.findFirst({
            where: {
                passwordResetToken: token,
                passwordResetExpires: { gt: new Date() },
            },
        });
        if (!user) {
            throw new Error('Invalid or expired reset token');
        }
        const passwordHash = await bcrypt_1.default.hash(newPassword, 10);
        await client_1.prisma.user.update({
            where: { id: user.id },
            data: {
                passwordHash,
                passwordResetToken: null,
                passwordResetExpires: null,
            },
        });
        await client_1.prisma.refreshToken.deleteMany({
            where: { userId: user.id },
        });
    }
}
exports.AuthService = AuthService;
//# sourceMappingURL=auth.service.js.map