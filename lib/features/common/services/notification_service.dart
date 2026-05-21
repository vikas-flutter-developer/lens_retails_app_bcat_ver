import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';

class NotificationService {
  Future<bool> sendNotification({
    required String channel,
    required String recipient,
    required String message,
  }) async {
    try {
      final response = await ApiClient.dio.post('v1/notifications/send', data: {
        'channel': channel,
        'recipient': recipient,
        'message': message,
      });
      return response.statusCode == 200 || response.statusCode == 202;
    } catch (e) {
      debugPrint('❌ [NotificationService] Error sending notification: $e');
      return false;
    }
  }
}
