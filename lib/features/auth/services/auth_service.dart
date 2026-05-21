import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/mock/mock_data.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static String? lastError;

  Future<bool> login(String email, String password) async {
    lastError = null;

    try {
      final response = await ApiClient.dio.post('v1/auth/login', data: {
        'email': email,
        'password': password,
      });

      final resData = response.data;
      final data = resData['data'] ?? resData;

      final token = data['token']?.toString() ?? '';
      final refreshToken = data['refreshToken']?.toString() ?? '';
      final user = data['user'] is Map ? data['user'] : {};
      final fullName = user['fullName']?.toString() ?? 'User';
      final userEmail = user['email']?.toString() ?? email;
      final userId = user['id']?.toString() ?? '';
      final userRole = user['role']?.toString() ?? 'OWNER';
      final subPlan = user['subscriptionPlan']?.toString() ?? '';
      final subExpires = user['subscriptionExpiresAt']?.toString() ?? '';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('auth_refresh_token', refreshToken);
      await prefs.setString('auth_user_name', fullName);
      await prefs.setString('auth_user_email', userEmail);
      await prefs.setString('auth_user_id', userId);
      await prefs.setString('auth_user_role', userRole);
      await prefs.setString('auth_subscription_plan', subPlan);
      await prefs.setString('auth_subscription_expires_at', subExpires);
      await prefs.setString('customerId', userId);
      return true;
    } on DioException catch (e) {
      lastError = e.response?.data is Map
          ? e.response?.data['message']?.toString() ?? 'Login failed'
          : 'Login failed';
      return false;
    } catch (e) {
      lastError = e.toString();
      return false;
    }
  }

  Future<void> authenticateSilently() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      await login('retail.user@local', 'local');
    }
  }

  Future<bool> adminLogin(String email, String password, {String role = 'OWNER'}) async {
    final ok = await login(email, password);
    if (!ok) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_user_role', role);
    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('auth_refresh_token');
    
    if (!AppConfig.useMockData && refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await ApiClient.dio.post('v1/auth/logout', data: {
          'refreshToken': refreshToken,
        });
      } catch (e) {
        debugPrint('Logout API call failed: $e');
      }
    }

    await prefs.remove('auth_token');
    await prefs.remove('auth_refresh_token');
    await prefs.remove('auth_user_name');
    await prefs.remove('auth_user_email');
    await prefs.remove('auth_user_role');
    await prefs.remove('auth_user_id');
    await prefs.remove('auth_company_id');
    await prefs.remove('customerId');
  }

  Future<bool> refreshAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('auth_refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) return false;

      if (AppConfig.useMockData) {
        await prefs.setString('auth_token', 'mock_refreshed_token_54321');
        return true;
      }

      final response = await ApiClient.dio.post('v1/auth/refresh', data: {
        'refreshToken': refreshToken,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = response.data;
        final data = resData['data'] ?? resData;
        final newToken = data['token']?.toString() ?? '';
        if (newToken.isNotEmpty) {
          await prefs.setString('auth_token', newToken);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await ApiClient.dio.post('v1/auth/forgot-password', data: {
        'email': email,
      });

      final resData = response.data;
      final data = resData['data'] ?? resData;

      return {
        'success': resData['success'] ?? true,
        'message': resData['message'] ?? 'Reset link sent to email',
        'resetToken': (data is Map ? data['resetToken'] : null) ?? resData['resetToken']?.toString(),
      };
    } catch (e) {
      if (e is DioException) {
        final resData = e.response?.data;
        String errMsg = 'Failed to send reset link';
        if (resData is Map) {
          errMsg = resData['message']?.toString() ?? 'Failed to send reset link';
        }
        
        // Custom user-friendly mapping for wrong/unregistered email addresses
        if (e.response?.statusCode == 404 || 
            errMsg.toLowerCase().contains('not found') || 
            errMsg.toLowerCase().contains('no user') || 
            errMsg.toLowerCase().contains('invalid email')) {
          errMsg = 'This email address is not registered with us. Please check your spelling or register a new account.';
        }

        return {
          'success': false,
          'message': errMsg,
        };
      }
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    try {
      final response = await ApiClient.dio.post('v1/auth/reset-password', data: {
        'token': token,
        'newPassword': newPassword,
      });

      return {
        'success': response.data['success'] ?? true,
        'message': response.data['message'] ?? 'Password reset successful',
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'message': e.response?.data is Map
              ? e.response?.data['message']?.toString() ?? 'Password reset failed'
              : 'Password reset failed',
        };
      }
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_user_name') ?? 'User';
  }

  Future<String?> getCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_company_id');
  }

  Future<String?> getMongoUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_user_id');
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('customerId') ?? prefs.getString('auth_user_id');
  }

  Future<String?> getSubscriptionPlan() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_subscription_plan');
  }

  Future<String?> getSubscriptionExpiresAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_subscription_expires_at');
  }

  Future<Map<String, String?>> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'address': prefs.getString('auth_user_address'),
      'state': prefs.getString('auth_user_state'),
      'pincode': prefs.getString('auth_user_pincode'),
      'gstin': prefs.getString('auth_user_gstin'),
      'cardNumber': prefs.getString('auth_user_card'),
    };
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    try {
      final response = await ApiClient.dio.post('v1/auth/register', data: {
        'fullName': name,
        'email': email,
        'password': password,
        'role': role,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Account created successfully',
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Registration failed',
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'message': e.response?.data is Map
              ? e.response?.data['message']?.toString() ?? 'Registration failed'
              : 'Registration failed',
        };
      }
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> createRazorpayOrder({
    required double amount,
    String? name,
    String? email,
    String? phone,
    String? subscriptionPlan,
  }) async {
    try {
      final response = await ApiClient.dio.post('v1/auth/payment/create-order', data: {
        'amount': amount,
        'name': name,
        'email': email,
        'phone': phone,
        'subscriptionPlan': subscriptionPlan,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = response.data;
        final data = resData['data'] ?? resData;
        return {
          'success': true,
          'id': data['id'],
          'amount': data['amount'],
          'currency': data['currency'],
          'keyId': data['keyId'],
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed to create Razorpay order',
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'message': e.response?.data is Map
              ? e.response?.data['message']?.toString() ?? 'Failed to create Razorpay order'
              : 'Failed to create Razorpay order',
        };
      }
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> verifyPaymentAndRegister({
    required String orderId,
    required String paymentId,
    required String signature,
    required Map<String, dynamic> userData,
    required String subscriptionPlan,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('auth_user_name') ?? '';
      final savedEmail = prefs.getString('auth_user_email') ?? '';

      final response = await ApiClient.dio.post('v1/auth/payment/verify-register', data: {
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
        'userData': {
          'fullName': userData['name'] ?? savedName,
          'email': userData['email'] ?? savedEmail,
          'password': userData['password'] ?? 'RENEWAL_DUMMY_PASSWORD',
          'role': userData['role'] ?? 'OWNER',
          'phone': userData['phone'],
          'shopName': userData['shopName'],
          'address': userData['address'],
          'subscriptionPlan': subscriptionPlan,
        },
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Payment verified and account created',
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Payment verification or registration failed',
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'message': e.response?.data is Map
              ? e.response?.data['message']?.toString() ?? 'Payment verification or registration failed'
              : 'Payment verification or registration failed',
        };
      }
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<List<Map<String, dynamic>>> getOwners() async {
    try {
      final response = await ApiClient.dio.get('v1/auth/owners');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = response.data;
        final rawData = resData['data'] ?? resData;
        final List<Map<String, dynamic>> owners = [];
        
        if (rawData is List) {
          for (var item in rawData) {
            if (item is Map<String, dynamic>) {
              owners.add(item);
            }
          }
        } else if (rawData is Map) {
          rawData.forEach((key, value) {
            if (value is Map<String, dynamic>) {
              owners.add(Map<String, dynamic>.from(value));
            }
          });
        }
        return owners;
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching owners: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> updateRetailerProfile(Map<String, dynamic> updates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (updates.containsKey('address')) await prefs.setString('auth_user_address', updates['address'] ?? '');
      if (updates.containsKey('state')) await prefs.setString('auth_user_state', updates['state'] ?? '');
      if (updates.containsKey('pincode')) await prefs.setString('auth_user_pincode', updates['pincode']?.toString() ?? '');
      if (updates.containsKey('gstin')) await prefs.setString('auth_user_gstin', updates['gstin'] ?? '');
      if (updates.containsKey('cardNumber')) await prefs.setString('auth_user_card', updates['cardNumber'] ?? '');
      if (updates.containsKey('name')) await prefs.setString('auth_user_name', updates['name'] ?? '');
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
