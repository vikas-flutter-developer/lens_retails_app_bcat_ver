"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaymentController = void 0;
const crypto_1 = __importDefault(require("crypto"));
const response_util_1 = require("../utils/response.util");
const auth_service_1 = require("../services/auth.service");
const client_1 = require("@prisma/client");
const client_2 = require("../prisma/client");
class PaymentController {
    static async createOrder(req, res) {
        try {
            const { amount, name, email, phone, subscriptionPlan } = req.body;
            if (!amount) {
                return (0, response_util_1.sendError)(res, 'Amount is required', 400);
            }
            const amountInPaise = Math.round(Number(amount) * 100);
            const keyId = process.env.RAZORPAY_KEY_ID || 'rzp_live_SoqYaLiOI6KmXVV';
            const keySecret = process.env.RAZORPAY_KEY_SECRET || 'BpcRWKFmvzYrrmJ1jvbO6Whee';
            const authString = Buffer.from(`${keyId}:${keySecret}`).toString('base64');
            const response = await fetch('https://api.razorpay.com/v1/orders', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Basic ${authString}`,
                },
                body: JSON.stringify({
                    amount: amountInPaise,
                    currency: 'INR',
                    receipt: `rcpt_${Date.now()}`,
                    notes: {
                        customerName: name || '',
                        customerEmail: email || '',
                        customerPhone: phone || '',
                        subscriptionPlan: subscriptionPlan || '',
                    }
                }),
            });
            if (!response.ok) {
                const errText = await response.text();
                return (0, response_util_1.sendError)(res, `Failed to create Razorpay order: ${errText}`, response.status);
            }
            const orderData = await response.json();
            return (0, response_util_1.sendSuccess)(res, {
                data: {
                    id: orderData.id,
                    amount: orderData.amount,
                    currency: orderData.currency,
                    keyId: keyId,
                    customer: {
                        name: name || null,
                        email: email || null,
                        phone: phone || null,
                        subscriptionPlan: subscriptionPlan || null,
                    }
                },
            }, 'Razorpay order created successfully', 201);
        }
        catch (error) {
            return (0, response_util_1.sendError)(res, error.message || 'Order creation failed');
        }
    }
    static async verifyPaymentAndRegister(req, res) {
        try {
            const { razorpay_order_id, razorpay_payment_id, razorpay_signature, userData } = req.body;
            if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
                return (0, response_util_1.sendError)(res, 'Missing payment verification details', 400);
            }
            if (!userData || !userData.email) {
                return (0, response_util_1.sendError)(res, 'Missing user email for verification', 400);
            }
            const keySecret = process.env.RAZORPAY_KEY_SECRET || 'BpcRWKFmvzYrrmJ1jvbO6Whee';
            const text = `${razorpay_order_id}|${razorpay_payment_id}`;
            const generatedSignature = crypto_1.default
                .createHmac('sha256', keySecret)
                .update(text)
                .digest('hex');
            if (generatedSignature !== razorpay_signature) {
                return (0, response_util_1.sendError)(res, 'Payment verification failed (invalid signature)', 400);
            }
            let subscriptionExpiresAt;
            let subPlan = userData.subscriptionPlan;
            if (!subPlan) {
                if (razorpay_signature.includes('1_month')) {
                    subPlan = '1 Month';
                }
                else if (razorpay_signature.includes('6_months')) {
                    subPlan = '6 Months';
                }
                else if (razorpay_signature.includes('1_year')) {
                    subPlan = '1 Year';
                }
                else {
                    subPlan = '1 Month';
                }
            }
            const existingUser = await client_2.prisma.user.findUnique({
                where: { email: userData.email },
            });
            if (subPlan) {
                let baseDate = new Date();
                if (existingUser && existingUser.subscriptionExpiresAt && new Date(existingUser.subscriptionExpiresAt) > new Date()) {
                    baseDate = new Date(existingUser.subscriptionExpiresAt);
                }
                subscriptionExpiresAt = baseDate;
                if (subPlan === '1 Month') {
                    subscriptionExpiresAt.setDate(subscriptionExpiresAt.getDate() + 30);
                }
                else if (subPlan === '6 Months') {
                    subscriptionExpiresAt.setDate(subscriptionExpiresAt.getDate() + 180);
                }
                else if (subPlan === '1 Year') {
                    subscriptionExpiresAt.setDate(subscriptionExpiresAt.getDate() + 365);
                }
            }
            let user;
            if (existingUser) {
                user = await client_2.prisma.user.update({
                    where: { email: userData.email },
                    data: {
                        subscriptionPlan: subPlan || null,
                        subscriptionExpiresAt: subscriptionExpiresAt || null,
                    },
                    select: {
                        id: true,
                        fullName: true,
                        email: true,
                        role: true,
                        subscriptionPlan: true,
                        subscriptionExpiresAt: true,
                        createdAt: true,
                    }
                });
                if (userData.phone) {
                    await client_2.prisma.employee.upsert({
                        where: { userId: user.id },
                        update: { phone: userData.phone },
                        create: {
                            userId: user.id,
                            name: userData.fullName || user.fullName,
                            role: user.role.toString(),
                            phone: userData.phone,
                            status: 'Active'
                        }
                    });
                }
            }
            else {
                if (!userData.fullName || !userData.password) {
                    return (0, response_util_1.sendError)(res, 'Missing user registration details (fullName and password are required)', 400);
                }
                const role = userData.role || client_1.UserRole.OWNER;
                user = await auth_service_1.AuthService.register({
                    fullName: userData.fullName,
                    email: userData.email,
                    password: userData.password,
                    role,
                    subscriptionPlan: subPlan || undefined,
                    subscriptionExpiresAt: subscriptionExpiresAt || undefined,
                });
                if (userData.phone) {
                    await client_2.prisma.employee.create({
                        data: {
                            userId: user.id,
                            name: userData.fullName,
                            role: role.toString(),
                            phone: userData.phone,
                            status: 'Active'
                        }
                    });
                }
                if (role === client_1.UserRole.OWNER && userData.shopName) {
                    await client_2.prisma.storeSettings.create({
                        data: {
                            storeName: userData.shopName,
                            address: userData.address || null,
                            phone: userData.phone || null,
                            email: userData.email || null
                        }
                    });
                }
            }
            return (0, response_util_1.sendSuccess)(res, { data: user }, 'Payment verified and User registered successfully', 201);
        }
        catch (error) {
            if (error.message === 'Email already in use') {
                return (0, response_util_1.sendError)(res, error.message, 409);
            }
            return (0, response_util_1.sendError)(res, error.message || 'Payment verification or registration failed');
        }
    }
    static async getAllOwners(req, res) {
        try {
            const owners = await client_2.prisma.user.findMany({
                where: { role: client_1.UserRole.OWNER },
                select: {
                    id: true,
                    fullName: true,
                    email: true,
                    role: true,
                    subscriptionPlan: true,
                    subscriptionExpiresAt: true,
                    createdAt: true,
                    employee: {
                        select: {
                            phone: true,
                        },
                    },
                },
                orderBy: { createdAt: 'desc' }
            });
            const formattedOwners = owners.map(owner => ({
                id: owner.id,
                fullName: owner.fullName,
                email: owner.email,
                phone: owner.employee?.phone || null,
                role: owner.role,
                subscriptionPlan: owner.subscriptionPlan,
                subscriptionExpiresAt: owner.subscriptionExpiresAt,
                createdAt: owner.createdAt,
            }));
            return (0, response_util_1.sendSuccess)(res, formattedOwners, 'Owners retrieved successfully');
        }
        catch (error) {
            return (0, response_util_1.sendError)(res, error.message || 'Failed to retrieve owners');
        }
    }
}
exports.PaymentController = PaymentController;
//# sourceMappingURL=payment.controller.js.map