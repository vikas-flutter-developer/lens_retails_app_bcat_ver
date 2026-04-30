import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/mock/mock_data.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  // Test Credentials for Silent Auth
  static const String _testEmail = 'branding@gmail.com';
  static const String _testPassword = 'branding';
  
  static String? lastError;

  Future<bool> login(String email, String password) async {
    lastError = null;

    if (AppConfig.useMockData) {
      debugPrint('🧪 [AuthService] MOCK MODE: Logging in as ${MockData.mockUser['name']}');
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate delay
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', MockData.mockUser['token']);
      await prefs.setString('auth_user_name', MockData.mockUser['name']);
      await prefs.setString('auth_user_email', MockData.mockUser['email']);
      await prefs.setString('auth_user_id', MockData.mockUser['id']);
      await prefs.setString('auth_company_id', MockData.mockUser['companyId']);
      await prefs.setString('customerId', MockData.mockUser['accountId']);
      return true;
    }

    try {
      debugPrint('🔐 [AuthService] Calling login API with accountId: $email');
      final response = await ApiClient.dio.post(
        'customer/login', // Use /api prefix to match production backend
        data: {'accountId': email, 'password': password},
      );

      debugPrint('🔐 [AuthService] Login response status: ${response.statusCode}');
      debugPrint('🔐 [AuthService] Login response headers: ${response.headers}');
      debugPrint('🔐 [AuthService] Login response BODY: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        String? token;
        
        // 1. Check Body for Token
        if (data is Map<String, dynamic>) {
          token = data['token'] ?? data['accessToken'] ?? data['access_token'];
          if (token == null && data['data'] is Map) {
            token = data['data']['token'] ?? data['data']['accessToken'];
          }
        }

        // 2. Check Headers for Token (Common patterns)
        if (token == null) {
          final authHeader = response.headers.value('authorization');
          if (authHeader != null && authHeader.toLowerCase().startsWith('bearer ')) {
             token = authHeader.substring(7);
          }
          token ??= response.headers.value('x-auth-token');
        }

        debugPrint(
          '🔐 [AuthService] Extracted token: ${token != null ? "Token Found" : "NO TOKEN FOUND"}',
        );

        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          
          // Save User Data (Handle both camelCase and TitleCase from backend)
          if (data is Map && (data['customer'] is Map || data['user'] is Map)) {
             final userMap = data['customer'] ?? data['user'];
             
             // 1. Save Name
             final name = userMap['name'] ?? userMap['Name'];
             if (name != null) await prefs.setString('auth_user_name', name);
             
             // 2. Save Email
             final emailValue = userMap['email'] ?? userMap['Email'];
             if (emailValue != null) await prefs.setString('auth_user_email', emailValue);
             
             // 3. Save Mongo ID
             final userId = userMap['id'] ?? userMap['_id'] ?? userMap['Id'];
             if (userId != null) await prefs.setString('auth_user_id', userId.toString());
             
             // 3.1 Save Company ID
             final compId = userMap['companyId'] ?? userMap['CompanyId'];
             if (compId != null) await prefs.setString('auth_company_id', compId.toString());
             
             // 4. CRITICAL: Save Account ID (Phone/Code) for Order Linkage
             // Backend returns 'AccountId' for customers
             String? accId = userMap['accountId'] ?? userMap['AccountId'] ?? userMap['phone'] ?? userMap['accountCode'];
             
             // If not in response, use the input credential if it looks like a phone/id
             if (accId == null && !email.contains('@')) {
               accId = email; 
             }
             
             if (accId != null) {
               await prefs.setString('customerId', accId);
               debugPrint('🔐 [AuthService] Account Linkage ID saved: $accId');
             }
             
             // Save extra details for Profile Dialog
             await _saveAdditionalUserData(userMap);
          }
          
          debugPrint('🔐 [AuthService] Token & User Data saved to SharedPreferences');
          return true;
        } else {
           // Fallback logic
           if (data is Map && data['customer'] != null) {
              // ... cookie logic ...
              // Still try to save customerId if possible
              final customer = data['customer'];
              String? accId = customer['accountId'] ?? customer['phone'];
              if (accId != null) {
                 final prefs = await SharedPreferences.getInstance();
                 await prefs.setString('customerId', accId);
              }
              
              debugPrint('⚠️ [AuthService] Login successful (Customer found) but NO TOKEN detected.');
              return true;
           }
           lastError = "Login succeeded but no token found.";
        }
      } else {
        lastError = "Server Error: ${response.statusCode}";
      }
      return false;
    } on DioException catch (e) {
      debugPrint('🔐 [AuthService] Login DioException: ${e.response?.statusCode} - ${e.response?.data}');
      debugPrint('🔐 [AuthService] Exception Type: ${e.type}');
      debugPrint('🔐 [AuthService] Exception Message: ${e.message}');
      debugPrint('🔐 [AuthService] Exception Error: ${e.error}');
      if (e.response != null) {
         if (e.response?.statusCode == 400 || e.response?.statusCode == 401) {
            lastError = "Wrong Account ID or Password";
         } else {
            lastError = "API Error: ${e.response?.statusCode} ${e.response?.statusMessage}";
         }
      } else {
         lastError = "Network Error: ${e.message}";
      }
      return false;
    } catch (e) {
      debugPrint('🔐 [AuthService] Login Error: $e');
      lastError = "App Error: $e";
      return false;
    }
  }

  /// Silently authenticates using hardcoded credentials to ensure internal APIs work
  Future<void> authenticateSilently() async {
    try {
      debugPrint('🔐 [AuthService] Attempting silent authentication...');
      final success = await login(_testEmail, _testPassword);
      if (success) {
        debugPrint('🔓 [AuthService] Silent authentication successful!');
      } else {
        debugPrint('🔒 [AuthService] Silent authentication failed.');
      }
    } catch (e) {
      debugPrint('🔒 [AuthService] Silent authentication error: $e');
    }
  }

  /// Admin login using email/password via /api/auth/login endpoint
  Future<bool> adminLogin(String email, String password, {String role = 'Admin'}) async {
    lastError = null;

    if (AppConfig.useMockData) {
      debugPrint('🧪 [AuthService] MOCK MODE: Admin login as ${MockData.mockUser['name']}');
      await Future.delayed(const Duration(milliseconds: 800));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', MockData.mockUser['token']);
      await prefs.setString('auth_user_name', MockData.mockUser['name']);
      await prefs.setString('auth_user_role', 'Admin');
      return true;
    }

    try {
      debugPrint('🔐 [AuthService] Calling ADMIN login API with email: $email, role: $role');
      final response = await ApiClient.dio.post(
        'auth/login',
        data: {'email': email, 'password': password, 'role': role},
      );

      debugPrint('🔐 [AuthService] Admin Login response status: ${response.statusCode}');
      debugPrint('🔐 [AuthService] Admin Login response BODY: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        String? token;
        
        // Extract token from response
        if (data is Map<String, dynamic>) {
          token = data['token'] ?? data['accessToken'] ?? data['access_token'];
        }

        // Check headers if not in body
        if (token == null) {
          final authHeader = response.headers.value('authorization');
          if (authHeader != null && authHeader.toLowerCase().startsWith('bearer ')) {
             token = authHeader.substring(7);
          }
        }

        debugPrint('🔐 [AuthService] Admin token: ${token != null ? "Token Found" : "NO TOKEN FOUND"}');

        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          
          // Save Admin User Data
          if (data is Map && data['user'] is Map) {
             final user = data['user'];
             if (user['name'] != null) await prefs.setString('auth_user_name', user['name']);
             if (user['email'] != null) await prefs.setString('auth_user_email', user['email']);
             if (user['role'] != null) await prefs.setString('auth_user_role', user['role']);
             
             // Save Admin ID
             final userId = user['id'] ?? user['_id'];
             if (userId != null) await prefs.setString('auth_user_id', userId.toString());
             
             // Save Company ID
             final compId = user['companyId'] ?? user['CompanyId'];
             if (compId != null) await prefs.setString('auth_company_id', compId.toString());
             
             debugPrint('🔐 [AuthService] Admin user data saved: ${user['name']} (${user['role']})');
          }
          
          debugPrint('🔐 [AuthService] Admin Token & User Data saved to SharedPreferences');
          return true;
        } else {
           lastError = "Login succeeded but no token found.";
        }
      } else {
        lastError = "Server Error: ${response.statusCode}";
      }
      return false;
    } on DioException catch (e) {
      debugPrint('🔐 [AuthService] Admin Login DioException: ${e.response?.statusCode} - ${e.response?.data}');
      debugPrint('🔐 [AuthService] Admin Exception Type: ${e.type}');
      debugPrint('🔐 [AuthService] Admin Exception Message: ${e.message}');
      debugPrint('🔐 [AuthService] Admin Exception Error: ${e.error}');
      if (e.response != null) {
         if (e.response?.statusCode == 400 || e.response?.statusCode == 401) {
            lastError = "Wrong Email or Password";
         } else {
            lastError = "API Error: ${e.response?.statusCode} ${e.response?.statusMessage}";
         }
      } else {
         lastError = "Network Error: ${e.message}";
      }
      return false;
    } catch (e) {
      debugPrint('🔐 [AuthService] Admin Login Error: $e');
      lastError = "App Error: $e";
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user_name');
    await prefs.remove('auth_user_email');
    await prefs.remove('auth_user_role');
    await prefs.remove('auth_user_id');
    await prefs.remove('auth_company_id');
    await prefs.remove('customerId');
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
    
    // Prioritize the Account ID (Phone) which we store as 'customerId'
    String? accountId = prefs.getString('customerId');
    
    // If accountId is null or looks like a Mongo ID (24 hex chars), 
    // and we have a separate phone number saved, use that.
    if (accountId == null || (accountId.length == 24 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(accountId))) {
       final mobile = prefs.getString('auth_user_mobile');
       if (mobile != null && mobile.isNotEmpty) {
          return mobile;
       }
    }
    
    return accountId ?? prefs.getString('auth_user_id'); 
  }

  Future<Map<String, String?>> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'address': prefs.getString('auth_user_address'),
      'state': prefs.getString('auth_user_state'),
      'pincode': prefs.getString('auth_user_pincode'),
      'gstin': prefs.getString('auth_user_gstin'),
      'cardNumber': prefs.getString('auth_user_card'),
      // Note: We don't store password for security, but user requested it. 
      // We will check if it's available or return null.
    };
  }

  Future<void> _saveAdditionalUserData(Map<String, dynamic> customer) async {
     final prefs = await SharedPreferences.getInstance();
     
     // Support both TitleCase (Original) and lowercase (Production API Sample)
     final address = customer['address'] ?? customer['Address'];
     final state = customer['state'] ?? customer['State'];
     final pincode = customer['pincode'] ?? customer['Pincode'];
     final gstin = customer['gstin'] ?? customer['GSTIN'];
     final cardNumber = customer['cardNumber'] ?? customer['CardNumber'];
     final mobile = customer['mobileNumber'] ?? customer['MobileNumber'];

     if (address != null) await prefs.setString('auth_user_address', address);
     if (state != null) await prefs.setString('auth_user_state', state);
     if (pincode != null) await prefs.setString('auth_user_pincode', pincode.toString());
     if (gstin != null) await prefs.setString('auth_user_gstin', gstin);
     if (cardNumber != null) await prefs.setString('auth_user_card', cardNumber);
     if (mobile != null) await prefs.setString('auth_user_mobile', mobile);
  }



  /// Register a new retailer account
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      debugPrint('📝 [AuthService] Registration Flow Started');

      // 1. SILENT ADMIN LOGIN
      // We need an Admin Token to create an account.
      // Using credentials from `spec.md` (and JSON collection)
      debugPrint('🔄 [AuthService] 1. Acquiring Admin Access...');
      final adminLoginResponse = await ApiClient.dio.post(
        'auth/login',
        data: {'email': 'branding@gmail.com', 'password': 'branding'},
      );
      
      String? adminToken;
      if (adminLoginResponse.statusCode == 200) {
        final data = adminLoginResponse.data;
        adminToken = data['token'] ?? data['accessToken'];
        if (adminToken == null && adminLoginResponse.headers.value('authorization') != null) {
           adminToken = adminLoginResponse.headers.value('authorization')?.replaceAll('Bearer ', '');
        }
      }
      
      if (adminToken == null) {
         throw Exception('Failed to acquire Admin Access (Token null)');
      }
      debugPrint('✅ [AuthService] Admin Access Granted');

      // 2. CREATE ACCOUNT
      debugPrint('📝 [AuthService] 2. Creating Account: $name / $phone');
      
      // Construct Payload based on User's Sample
      final payload = {
        "Name": name,
        "Alias": "",
        "PrintName": name,
        "AccountId": phone, // Using Phone as unique Account ID
        "Groups": ["RETAILER"],
        "AccountCategory": "",
        "AccountDealerType": "Registerd",
        "AccountType": "",
        "Address": "",
        "AdharCardNumber": 0,
        "CardNumber": "",
        "ContactPerson": name,
        "CreditLimit": 0,
        "CstNumber": 0,
        "DayLimit": "",
        "Distance": "",
        "Dnd": "",
        "Email": email,
        "EnableLoyality": "Y",
        "Ex1": "",
        "GSTIN": "",
        "ItPlan": "",
        "LstNumber": 0,
        "MobileNumber": phone,
        "OpeningBalance": {"balance": 0, "type": "Dr"},
        "Password": password,
        "Pincode": "",
        "PreviousYearBalance": {"balance": 0, "type": "Dr"},
        "State": "Maharashtra",
        "Stations": ["Main"], // Backend requires at least one station
        "TelNumber": "",
        "Transporter": ""
      };

      final createResponse = await ApiClient.dio.post(
        'accounts/add-account',
        data: payload,
        options: Options(
          headers: {'Authorization': 'Bearer $adminToken'}, // Explicitly use Admin Token
        ),
      );

      debugPrint('📝 [AuthService] Add-Account Response: ${createResponse.statusCode}');

      if (createResponse.statusCode == 200 || createResponse.statusCode == 201) {
        debugPrint('✅ [AuthService] Account Created Successfully!');
        
        // 3. AUTO-LOGIN AS USER
        debugPrint('🔄 [AuthService] 3. logging in as new user...');
        await Future.delayed(const Duration(milliseconds: 500)); // Sync wait
        
        // We log in normally, which will save the USER token to SharedPreferences
        // effectively "logging out" the admin and "logging in" the user in the app state.
        final loginSuccess = await login(email, password); // Note: Login usually uses Email or AccountId
        
        // Fallback: Try Login with Phone if Email fail (Backend ambiguity)
        if (!loginSuccess) {
           debugPrint('⚠️ [AuthService] Email Login failed. Trying Phone Login...');
           await login(phone, password);
        }
        
        return {
          'success': true,
          'customerId': phone,
          'name': name,
          'email': email,
          'message': 'Account created & logged in!',
        };
      }
      
      return {
        'success': false,
        'message': 'Registration failed: Status ${createResponse.statusCode}',
      };
    } on DioException catch (e) {
      debugPrint('❌ [AuthService] Registration error: ${e.response?.data}');
      
      String errorMessage = 'Registration failed';
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        errorMessage = e.response?.data['message'];
      } else if (e.response?.statusCode == 409) {
          errorMessage = 'Account ID already exists.';
      } else if (e.response?.statusCode == 401) {
          errorMessage = 'Server Authorization Failed (Admin).';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      debugPrint('❌ [AuthService] Unexpected registration error: $e');
      return {
        'success': false,
        'message': 'Unexpected error: $e',
      };
    }
  }

  /// Updates the retailer profile (GSTIN, Address, etc.)
  /// Uses silent admin login to permit the update.
  Future<Map<String, dynamic>> updateRetailerProfile(Map<String, dynamic> updates) async {
    try {
      debugPrint('📝 [AuthService] Update Profile Started');
      
      // 1. Get current User ID (Mongo ID)
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('auth_user_id');
      
      if (userId == null) throw Exception('User ID not found');

      // 2. Silent Admin Login (Reuse existing pattern)
      debugPrint('🔄 [AuthService] Acquiring Admin Access for Update...');
      final adminLoginResponse = await ApiClient.dio.post(
        'auth/login',
        data: {'email': 'branding@gmail.com', 'password': 'branding'},
      );
      
      String? adminToken;
      if (adminLoginResponse.statusCode == 200) {
        final data = adminLoginResponse.data;
        adminToken = data['token'] ?? data['accessToken'];
      }
      
      if (adminToken == null) throw Exception('Failed to acquire Admin Token');

      // 3. Construct Update Payload
      // We map UI keys to Backend keys
      final payload = <String, dynamic>{};
      
      // If we are updating specific fields, map them to backend schema
      if (updates.containsKey('address')) payload['Address'] = updates['address'];
      if (updates.containsKey('state')) payload['State'] = updates['state'];
      if (updates.containsKey('pincode')) payload['Pincode'] = updates['pincode'];
      if (updates.containsKey('city')) payload['City'] = updates['city']; // Added City just in case
      if (updates.containsKey('gstin')) payload['GSTIN'] = updates['gstin'];
      if (updates.containsKey('cardNumber')) payload['CardNumber'] = updates['cardNumber'];
      if (updates.containsKey('name')) {
         payload['Name'] = updates['name'];
         payload['PrintName'] = updates['name'];
         payload['ContactPerson'] = updates['name'];
      }
      
      debugPrint('📝 [AuthService] Updating Account $userId with payload: $payload');

      final response = await ApiClient.dio.put(
        '/api/accounts/update/$userId',
        data: payload,
        options: Options(headers: {'Authorization': 'Bearer $adminToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
         debugPrint('✅ [AuthService] Update Successful');
         
         // 4. Update Local Storage immediately
         if (payload['Address'] != null) await prefs.setString('auth_user_address', payload['Address']);
         if (payload['State'] != null) await prefs.setString('auth_user_state', payload['State']);
         if (payload['Pincode'] != null) await prefs.setString('auth_user_pincode', payload['Pincode']);
         if (payload['GSTIN'] != null) await prefs.setString('auth_user_gstin', payload['GSTIN']);
         if (payload['CardNumber'] != null) await prefs.setString('auth_user_card', payload['CardNumber']);
         if (payload['Name'] != null) await prefs.setString('auth_user_name', payload['Name']);
         
         return {'success': true};
      }
      
      return {'success': false, 'message': 'Update failed: ${response.statusCode}'};
      
    } catch (e) {
      debugPrint('❌ [AuthService] Update Error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}
