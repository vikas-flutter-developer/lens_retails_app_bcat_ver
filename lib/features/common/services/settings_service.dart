import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';

class SettingsService {
  Future<Map<String, dynamic>?> getSettings() async {
    try {
      final response = await ApiClient.dio.get('v1/settings/store');
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [SettingsService] Error fetching settings: $e');
      return null;
    }
  }

  Future<bool> updateSettings(Map<String, dynamic> settings) async {
    try {
      final response = await ApiClient.dio.put('v1/settings/store', data: settings);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ [SettingsService] Error updating settings: $e');
      return false;
    }
  }
}
