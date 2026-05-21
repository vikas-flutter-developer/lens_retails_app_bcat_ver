export declare class InventoryService {
    create(body: {
        sku: string;
        name: string;
        kind: 'FRAME' | 'LENS' | 'ACCESSORY';
    }): {
        sku: string;
        name: string;
        kind: "FRAME" | "LENS" | "ACCESSORY";
        id: string;
        stockQuantity: number;
    };
    list(): never[];
    updateStock(id: string, quantity: number): {
        id: string;
        stockQuantity: number;
        updated: boolean;
    };
    history(id: string): {
        id: string;
        movements: never[];
    };
    alerts(): never[];
}
