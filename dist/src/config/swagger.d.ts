export declare const openApiDocument: {
    readonly openapi: "3.1.0";
    readonly info: {
        readonly title: "Retail Lens API";
        readonly version: "1.0.0";
        readonly description: "Backend APIs for optical retail operations";
    };
    readonly servers: readonly [{
        readonly url: "/api/v1";
    }];
    readonly paths: {
        readonly '/health': {
            readonly get: {
                readonly summary: "Health check";
                readonly responses: {
                    readonly '200': {
                        readonly description: "OK";
                    };
                };
            };
        };
        readonly '/auth/login': {
            readonly post: {
                readonly summary: "Login";
                readonly responses: {
                    readonly '200': {
                        readonly description: "Success";
                    };
                };
            };
        };
        readonly '/auth/refresh': {
            readonly post: {
                readonly summary: "Refresh token";
                readonly responses: {
                    readonly '200': {
                        readonly description: "Success";
                    };
                };
            };
        };
        readonly '/job-cards/{id}/items/{itemId}': {
            readonly delete: {
                readonly summary: "Remove job card item";
                readonly responses: {
                    readonly '200': {
                        readonly description: "Removed";
                    };
                };
            };
        };
        readonly '/job-cards/{id}/payments': {
            readonly post: {
                readonly summary: "Record payment";
                readonly responses: {
                    readonly '201': {
                        readonly description: "Created";
                    };
                };
            };
        };
        readonly '/inventory': {
            readonly get: {
                readonly summary: "List inventory";
                readonly responses: {
                    readonly '200': {
                        readonly description: "Success";
                    };
                };
            };
            readonly post: {
                readonly summary: "Create inventory item";
                readonly responses: {
                    readonly '201': {
                        readonly description: "Created";
                    };
                };
            };
        };
        readonly '/inventory/{id}': {
            readonly put: {
                readonly summary: "Update stock";
                readonly responses: {
                    readonly '200': {
                        readonly description: "Updated";
                    };
                };
            };
        };
        readonly '/inventory/{id}/history': {
            readonly get: {
                readonly summary: "Inventory history";
                readonly responses: {
                    readonly '200': {
                        readonly description: "Success";
                    };
                };
            };
        };
        readonly '/inventory/alerts': {
            readonly get: {
                readonly summary: "Inventory alerts";
                readonly responses: {
                    readonly '200': {
                        readonly description: "Success";
                    };
                };
            };
        };
        readonly '/tasks': {
            readonly get: {
                readonly summary: "Task summary";
                readonly responses: {
                    readonly '200': {
                        readonly description: "Success";
                    };
                };
            };
        };
        readonly '/employees/{id}/tasks': {
            readonly get: {
                readonly summary: "Employee task report";
                readonly responses: {
                    readonly '200': {
                        readonly description: "Success";
                    };
                };
            };
        };
        readonly '/reports/sales': {
            readonly get: {
                readonly summary: "Sales report";
                readonly responses: {
                    readonly '200': {
                        readonly description: "Success";
                    };
                };
            };
        };
        readonly '/finances/daily-summary': {
            readonly get: {
                readonly summary: "Daily finance summary";
                readonly responses: {
                    readonly '200': {
                        readonly description: "Success";
                    };
                };
            };
        };
        readonly '/finances/expenses': {
            readonly post: {
                readonly summary: "Create expense";
                readonly responses: {
                    readonly '201': {
                        readonly description: "Created";
                    };
                };
            };
        };
        readonly '/finances/expenses/{id}': {
            readonly put: {
                readonly summary: "Update expense";
                readonly responses: {
                    readonly '200': {
                        readonly description: "Updated";
                    };
                };
            };
            readonly delete: {
                readonly summary: "Delete expense";
                readonly responses: {
                    readonly '200': {
                        readonly description: "Deleted";
                    };
                };
            };
        };
        readonly '/settings/store': {
            readonly get: {
                readonly summary: "Get store settings";
                readonly responses: {
                    readonly '200': {
                        readonly description: "Success";
                    };
                };
            };
            readonly put: {
                readonly summary: "Update store settings";
                readonly responses: {
                    readonly '200': {
                        readonly description: "Updated";
                    };
                };
            };
        };
        readonly '/notifications/send': {
            readonly post: {
                readonly summary: "Queue notification";
                readonly responses: {
                    readonly '202': {
                        readonly description: "Queued";
                    };
                };
            };
        };
        readonly '/sync': {
            readonly post: {
                readonly summary: "Sync offline actions";
                readonly responses: {
                    readonly '202': {
                        readonly description: "Accepted";
                    };
                };
            };
        };
    };
};
