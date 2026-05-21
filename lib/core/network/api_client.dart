import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiClient {
  static const String baseUrl = AppConfig.apiBaseUrl;
  static GlobalKey<NavigatorState>? navigatorKey;
  

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-API-Key': AppConfig.apiKey,
      },
      // Disable credentials for web to prevent strict CORS origin-matching checks
      extra: {'withCredentials': false},
    ),
  );

  static Dio get dio => _dio;

  static void init() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Disable credentials for web to prevent strict CORS origin-matching checks
          options.extra['withCredentials'] = false;
          
          // Fallback: Also try Bearer token if present
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['X-API-Key'] = AppConfig.apiKey;
          
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
