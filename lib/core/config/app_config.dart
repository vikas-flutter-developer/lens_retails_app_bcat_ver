import 'package:flutter/foundation.dart';

class AppConfig {
  static const bool useMockData = false; // Global toggle for Mock Mode
  static const bool isProduction = true; // Set to TRUE to use live server, FALSE for local testing

  // Local Backend URLs
  static const String localUrl = kIsWeb
      ? 'http://localhost:3000/api/'
      : 'http://10.0.2.2:3000/api/';

  // Production Backend URL
  static const String productionUrl = 'https://lens-retail-appnew.onrender.com/api/';

  // Dynamic Base URL based on environment
  static const String apiBaseUrl = isProduction ? productionUrl : localUrl;

  static const String apiKey = 'test_api_key_12345';
  
  // App Info
  static const String appName = "Lens Retail Executive";
  static const String version = "2.1.0";
}
