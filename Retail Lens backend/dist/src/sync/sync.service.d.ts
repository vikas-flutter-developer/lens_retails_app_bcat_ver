export declare class SyncService {
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
