import { SyncService } from './sync.service';
export declare class SyncController {
    private readonly syncService;
    constructor(syncService: SyncService);
    ingest(body: {
        deviceId: string;
        idempotencyKey?: string;
        actions: Array<{
            actionType: string;
            payload: unknown;
        }>;
    }): {
        batchId: string;
        deviceId: string;
        accepted: number;
        conflicts: never[];
        idempotencyKey: string | null;
    };
}
