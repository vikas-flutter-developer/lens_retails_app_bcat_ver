"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.FinanceService = void 0;
const common_1 = require("@nestjs/common");
let FinanceService = class FinanceService {
    getDailySummary() {
        return {
            cashInHand: 0,
            salesToday: 0,
            deliveriesToday: 0,
            framesSoldToday: 0,
        };
    }
    createExpense(body) {
        return { id: 'expense_demo', ...body, createdAt: new Date().toISOString() };
    }
    updateExpense(id, body) {
        return { id, ...body, updatedAt: new Date().toISOString() };
    }
    deleteExpense(id) {
        return { id, deleted: true };
    }
};
exports.FinanceService = FinanceService;
exports.FinanceService = FinanceService = __decorate([
    (0, common_1.Injectable)()
], FinanceService);
//# sourceMappingURL=finance.service.js.map