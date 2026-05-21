export declare class NotificationsService {
    send(body: {
        channel: 'WHATSAPP' | 'EMAIL';
        recipient: string;
        message: string;
    }): {
        queuedAt: string;
        channel: "WHATSAPP" | "EMAIL";
        recipient: string;
        message: string;
        id: string;
        status: string;
    };
}
