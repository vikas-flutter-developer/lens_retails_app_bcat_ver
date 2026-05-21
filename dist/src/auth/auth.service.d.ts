export declare class AuthService {
    login(email: string, _password: string): {
        user: {
            id: string;
            email: string;
            role: string;
        };
        accessToken: string;
        refreshToken: string;
    };
    refresh(_refreshToken: string): {
        accessToken: string;
    };
}
