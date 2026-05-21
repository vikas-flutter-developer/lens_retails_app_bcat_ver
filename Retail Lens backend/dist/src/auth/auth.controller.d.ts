import { AuthService } from './auth.service';
export declare class AuthController {
    private readonly authService;
    constructor(authService: AuthService);
    login(body: {
        email: string;
        password: string;
    }): {
        user: {
            id: string;
            email: string;
            role: string;
        };
        accessToken: string;
        refreshToken: string;
    };
    refresh(body: {
        refreshToken: string;
    }): {
        accessToken: string;
    };
}
