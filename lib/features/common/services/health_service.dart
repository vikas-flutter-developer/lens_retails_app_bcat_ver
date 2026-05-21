import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';

class HealthService {
  Future<bool> checkHealth() async {
    try {
      final response = await ApiClient.dio.get('v1/health');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ [HealthService] Health check failed: $e');
      return false;
    }
  }
}
