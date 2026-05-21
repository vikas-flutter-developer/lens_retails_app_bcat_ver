"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.productsRouter = void 0;
const express_1 = require("express");
const products_controller_1 = require("../controllers/products.controller");
exports.productsRouter = (0, express_1.Router)();
exports.productsRouter.get('/qr/:qrCode', products_controller_1.ProductsController.getProductByQr);
//# sourceMappingURL=products.routes.js.map