import { Request, Response } from 'express';
import crypto from 'crypto';
import { sendSuccess, sendError } from '../utils/response.util';
import { AuthService } from '../services/auth.service';
import { UserRole } from '@prisma/client';
import { prisma } from '../prisma/client';

export class PaymentController {
  static async createOrder(req: Request, res: Response) {
    try {
      const { amount, name, email, phone, subscriptionPlan } = req.body; // Amount in INR, e.g. 2999

      if (!amount) {
        return sendError(res, 'Amount is required', 400);
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
        return sendError(res, `Failed to create Razorpay order: ${errText}`, response.status);
      }

      const orderData = await response.json();

      return sendSuccess(
        res,
        {
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
        },
        'Razorpay order created successfully',
        201
      );
    } catch (error: any) {
      return sendError(res, error.message || 'Order creation failed');
    }
  }

  static async verifyPaymentAndRegister(req: Request, res: Response) {
    try {
      const { razorpay_order_id, razorpay_payment_id, razorpay_signature, userData } = req.body;

      if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
        return sendError(res, 'Missing payment verification details', 400);
      }

      if (!userData || !userData.email) {
        return sendError(res, 'Missing user email for verification', 400);
      }

      // Verify the Razorpay signature strictly
      const keySecret = process.env.RAZORPAY_KEY_SECRET || 'BpcRWKFmvzYrrmJ1jvbO6Whee';
      const text = `${razorpay_order_id}|${razorpay_payment_id}`;
      const generatedSignature = crypto
        .createHmac('sha256', keySecret)
        .update(text)
        .digest('hex');

      if (generatedSignature !== razorpay_signature) {
        return sendError(res, 'Payment verification failed (invalid signature)', 400);
      }

      // Calculate subscription expiration date
      let subscriptionExpiresAt: Date | undefined;
      let subPlan = userData.subscriptionPlan; // e.g. "1 Month", "6 Months", "1 Year"

      // Smart fallback deduction for mock testing if subscriptionPlan is missing
      if (!subPlan) {
        if (razorpay_signature.includes('1_month')) {
          subPlan = '1 Month';
        } else if (razorpay_signature.includes('6_months')) {
          subPlan = '6 Months';
        } else if (razorpay_signature.includes('1_year')) {
          subPlan = '1 Year';
        } else {
          subPlan = '1 Month'; // Default fallback
        }
      }

      // Check if user already exists
      const existingUser = await prisma.user.findUnique({
        where: { email: userData.email },
      });

      if (subPlan) {
        // Base early renewal on existing expiration if it exists and is in the future (stacking)
        let baseDate = new Date();
        if (existingUser && existingUser.subscriptionExpiresAt && new Date(existingUser.subscriptionExpiresAt) > new Date()) {
          baseDate = new Date(existingUser.subscriptionExpiresAt);
        }

        subscriptionExpiresAt = baseDate;
        if (subPlan === '1 Month') {
          subscriptionExpiresAt.setDate(subscriptionExpiresAt.getDate() + 30);
        } else if (subPlan === '6 Months') {
          subscriptionExpiresAt.setDate(subscriptionExpiresAt.getDate() + 180);
        } else if (subPlan === '1 Year') {
          subscriptionExpiresAt.setDate(subscriptionExpiresAt.getDate() + 365);
        }
      }

      let user;
      if (existingUser) {
        // Renewal Flow: Update existing user's subscription details
        user = await prisma.user.update({
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

        // Create or update associated Employee profile with phone number if provided
        if (userData.phone) {
          await prisma.employee.upsert({
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
      } else {
        // Registration Flow: Create a new User
        if (!userData.fullName || !userData.password) {
          return sendError(res, 'Missing user registration details (fullName and password are required)', 400);
        }
        const role = userData.role || UserRole.OWNER;
        user = await AuthService.register({
          fullName: userData.fullName,
          email: userData.email,
          password: userData.password,
          role,
          subscriptionPlan: subPlan || undefined,
          subscriptionExpiresAt: subscriptionExpiresAt || undefined,
        });

        // Automatically create an Employee profile for the registered user
        if (userData.phone) {
          await prisma.employee.create({
            data: {
              userId: user.id,
              name: userData.fullName,
              role: role.toString(),
              phone: userData.phone,
              status: 'Active'
            }
          });
        }

        // Automatically create StoreSettings if it is an OWNER registration
        if (role === UserRole.OWNER && userData.shopName) {
          await prisma.storeSettings.create({
            data: {
              storeName: userData.shopName,
              address: userData.address || null,
              phone: userData.phone || null,
              email: userData.email || null
            }
          });
        }
      }

      return sendSuccess(
        res,
        { data: user },
        'Payment verified and User registered successfully',
        201
      );
    } catch (error: any) {
      if (error.message === 'Email already in use') {
        return sendError(res, error.message, 409);
      }
      return sendError(res, error.message || 'Payment verification or registration failed');
    }
  }

  static async getAllOwners(req: Request, res: Response) {
    try {
      const owners = await prisma.user.findMany({
        where: { role: UserRole.OWNER },
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

      return sendSuccess(res, formattedOwners, 'Owners retrieved successfully');
    } catch (error: any) {
      return sendError(res, error.message || 'Failed to retrieve owners');
    }
  }
}
