import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';

class SyncService {
  Future<Map<String, dynamic>?> syncData(Map<String, dynamic> payload) async {
    try {
      final response = await ApiClient.dio.post('v1/sync', data: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [SyncService] Error synchronizing data: $e');
      return null;
    }
  }
}
