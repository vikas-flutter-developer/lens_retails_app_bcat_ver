"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.JobCardsService = void 0;
const common_1 = require("@nestjs/common");
let JobCardsService = class JobCardsService {
    create(customerId) {
        return {
            id: 'jc_demo',
            customerId,
            status: 'DRAFT',
            createdAt: new Date().toISOString(),
        };
    }
    findOne(id) {
        return {
            id,
            status: 'DRAFT',
            items: [],
            payments: [],
        };
    }
    removeItem(jobCardId, itemId) {
        return { jobCardId, itemId, removed: true };
    }
    addPayment(jobCardId, payment) {
        return {
            id: 'payment_demo',
            jobCardId,
            ...payment,
            recordedAt: new Date().toISOString(),
        };
    }
};
exports.JobCardsService = JobCardsService;
exports.JobCardsService = JobCardsService = __decorate([
    (0, common_1.Injectable)()
], JobCardsService);
//# sourceMappingURL=job-cards.service.js.map