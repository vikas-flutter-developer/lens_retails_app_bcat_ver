export declare class SettingsService {
    getStoreSettings(): {
        storeName: string;
        gstNumber: null;
        address: null;
    };
    updateStoreSettings(body: {
        storeName: string;
        gstNumber?: string;
        address?: string;
    }): {
        updatedAt: string;
        storeName: string;
        gstNumber?: string;
        address?: string;
    };
}
