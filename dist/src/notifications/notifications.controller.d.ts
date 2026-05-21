import { NotificationsService } from './notifications.service';
export declare class NotificationsController {
    private readonly notificationsService;
    constructor(notificationsService: NotificationsService);
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
