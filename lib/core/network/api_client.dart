import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = ''; // DISCONNECTED MODE
  static GlobalKey<NavigatorState>? navigatorKey;
  // static const String baseUrl = 'http://10.0.2.2:5000/api/'; // Local Testing (Emulator)
  // static const String baseUrl = 'https://lens-project.apps.mytabletap.com/api/'; // Production
  
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      // Enable credentials for web (cookies sent automatically by browser)
      extra: {'withCredentials': true},
    ),
  );

  static Dio get dio => _dio;

  static void init() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add withCredentials for web cookie support
          options.extra['withCredentials'] = true;
          
          // Fallback: Also try Bearer token if present
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          // debugPrint('🌐 [API Request] ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // debugPrint('✅ [API Response] ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (e.response != null && e.response?.statusCode == 402) {
            // REDIRECT TO SUBSCRIPTION ON PAYMENT REQUIRED (EXPIRY)
            if (navigatorKey != null) {
               navigatorKey!.currentState?.pushNamedAndRemoveUntil('/subscription', (route) => false);
            }
          }
          return handler.next(e);
        },
      ),
    );
  }
}
