import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationUtil {
  /// Opens WhatsApp with a pre-filled message to the specified phone number.
  /// Ensure the number includes the country code, e.g., '+919876543210'.
  static Future<void> sendWhatsAppMessage(String phone, String message) async {
    // Remove '+' for the standard wa.me link format, or use it as is if standard scheme works
    final formattedPhone = phone.replaceAll(RegExp(r'[^\d]'), ''); 
    final url = Uri.parse('https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch WhatsApp for $phone';
    }
  }

  /// Example Template for Job Card Ready
  static String getJobCardReadyMessage(String customerName, String jobCode) {
    return 'Dear $customerName,\nYour order ($jobCode) is ready for pickup at our store! Please visit us to collect your glasses. Thank you for choosing us!';
  }

  /// Automated Background Emails Simulation
  /// This function mocks sending an email silently to the server and returns success.
  /// When the backend is ready, replace this with an `HttpClient` call to your email microservice.
  static Future<bool> sendAutomatedEmail(String toEmail, String subject, String body) async {
    // Simulate Network API POST request latency
    await Future.delayed(const Duration(seconds: 1));
    debugPrint('📧 [MOCK EMAIL SENT] to: $toEmail | Subject: $subject');
    return true; // Return true to indicate successful handoff to background worker
  }
}
