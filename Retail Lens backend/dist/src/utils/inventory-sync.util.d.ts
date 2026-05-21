export declare function deductInventoryForJobCard(jobCardId: string, txClient?: any): Promise<void>;
export declare function restoreInventoryForJobCard(jobCardId: string, isReturn?: boolean, txClient?: any): Promise<void>;
export declare function syncInventoryOnStatusChange(jobCardId: string, oldStatus: string, newStatus: string, txClient?: any): Promise<void>;
