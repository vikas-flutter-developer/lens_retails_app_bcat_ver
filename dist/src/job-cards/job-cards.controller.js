"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.JobCardsController = void 0;
const common_1 = require("@nestjs/common");
const job_cards_service_1 = require("./job-cards.service");
let JobCardsController = class JobCardsController {
    jobCardsService;
    constructor(jobCardsService) {
        this.jobCardsService = jobCardsService;
    }
    create(body) {
        return this.jobCardsService.create(body.customerId);
    }
    findOne(id) {
        return this.jobCardsService.findOne(id);
    }
    removeItem(id, itemId) {
        return this.jobCardsService.removeItem(id, itemId);
    }
    addPayment(id, body) {
        return this.jobCardsService.addPayment(id, body);
    }
};
exports.JobCardsController = JobCardsController;
__decorate([
    (0, common_1.Post)(),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], JobCardsController.prototype, "create", null);
__decorate([
    (0, common_1.Get)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], JobCardsController.prototype, "findOne", null);
__decorate([
    (0, common_1.Delete)(':id/items/:itemId'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Param)('itemId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], JobCardsController.prototype, "removeItem", null);
__decorate([
    (0, common_1.Post)(':id/payments'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", void 0)
], JobCardsController.prototype, "addPayment", null);
exports.JobCardsController = JobCardsController = __decorate([
    (0, common_1.Controller)('job-cards'),
    __metadata("design:paramtypes", [job_cards_service_1.JobCardsService])
], JobCardsController);
//# sourceMappingURL=job-cards.controller.js.map