import { UserRole } from '@prisma/client';
export declare class AuthService {
    static register(data: {
        fullName: string;
        email: string;
        password: string;
        role: UserRole;
        subscriptionPlan?: string;
        subscriptionExpiresAt?: Date;
    }): Promise<{
        id: string;
        createdAt: Date;
        email: string;
        fullName: string;
        role: import("@prisma/client").$Enums.UserRole;
        subscriptionExpiresAt: Date | null;
        subscriptionPlan: string | null;
    }>;
    static login(data: {
        email: string;
        password: string;
    }): Promise<{
        token: string;
        refreshToken: string;
        user: {
            id: string;
            fullName: string;
            email: string;
            role: import("@prisma/client").$Enums.UserRole;
            subscriptionPlan: string | null;
            subscriptionExpiresAt: Date | null;
        };
    }>;
    static refresh(token: string): Promise<{
        token: string;
    }>;
    static logout(refreshToken: string): Promise<void>;
    static forgotPassword(email: string): Promise<{
        resetToken: string;
    }>;
    static resetPassword(token: string, newPassword: string): Promise<void>;
}
