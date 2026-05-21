import { InventoryKind } from '@prisma/client';
export interface StockBatch {
    id: string;
    createdAt: Date;
    originalQuantity: number;
    remainingQuantity: number;
    reason: string;
}
export declare class InventoryService {
    static getAllInventory(): Promise<{
        id: string;
        sku: string;
        name: string;
        kind: import("@prisma/client").$Enums.InventoryKind;
        stockQuantity: number;
        reorderLevel: number;
        vendorId: string | null;
        salePrice: number;
        powerSpecs: import("@prisma/client/runtime/library").JsonValue;
    }[]>;
    static createInventoryProduct(data: {
        sku: string;
        name: string;
        kind: InventoryKind;
        stockQuantity: number;
        reorderLevel: number;
        salePrice?: number;
        vendorId?: string;
        powerSpecs?: any;
    }): Promise<{
        id: string;
        sku: string;
        name: string;
        kind: import("@prisma/client").$Enums.InventoryKind;
        stockQuantity: number;
        reorderLevel: number;
        vendorId: string | null;
        salePrice: number;
        powerSpecs: import("@prisma/client/runtime/library").JsonValue;
    }>;
    static getLowStockAlerts(): Promise<{
        id: string;
        sku: string;
        name: string;
        kind: import("@prisma/client").$Enums.InventoryKind;
        stockQuantity: number;
        reorderLevel: number;
    }[]>;
    static getProductMovementHistory(productId: string): Promise<{
        id: string;
        createdAt: Date;
        productId: string;
        quantity: number;
        reason: string;
        createdById: string | null;
    }[]>;
    static updateInventoryProductQuantity(id: string, quantity: number, createdById?: string, reason?: string): Promise<{
        id: string;
        sku: string;
        name: string;
        kind: import("@prisma/client").$Enums.InventoryKind;
        stockQuantity: number;
        reorderLevel: number;
        salePrice: number;
        vendorId: string | null;
        powerSpecs: import("@prisma/client/runtime/library").JsonValue | null;
        createdAt: Date;
        updatedAt: Date;
    }>;
    static updateInventoryProduct(id: string, data: {
        name?: string;
        salePrice?: number;
        vendorId?: string | null;
        powerSpecs?: any;
        quantity?: number;
        reason?: string;
        createdById?: string;
    }): Promise<{
        id: string;
        sku: string;
        name: string;
        kind: import("@prisma/client").$Enums.InventoryKind;
        stockQuantity: number;
        reorderLevel: number;
        salePrice: number;
        vendorId: string | null;
        powerSpecs: import("@prisma/client/runtime/library").JsonValue | null;
        createdAt: Date;
        updatedAt: Date;
    }>;
    static getFIFOBatches(productId: string): Promise<StockBatch[]>;
}
