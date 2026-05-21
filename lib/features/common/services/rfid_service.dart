import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';

class RfidService {
  /// 📊 1. BATCH AUDIT: Sends physical array of detected IDs to trigger logic check.
  Future<Map<String, dynamic>?> runBatchAudit(List<String> scannedEpcs) async {
    try {
      final response = await ApiClient.dio.post(
        'v1/rfid/batch-audit',
        data: { 'scannedEpcs': scannedEpcs },
        options: Options(headers: {'Connection': 'close'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data; // Contains matched/missing breakdown directly at root
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// 🛍️ 2. SMART CHECKOUT: Pulls instant consolidated bill pricing.
  Future<Map<String, dynamic>?> requestSmartCheckout(List<String> cartEpcs) async {
    try {
      final response = await ApiClient.dio.post(
        'v1/rfid/smart-checkout',
        data: { 'cartEpcs': cartEpcs },
        options: Options(headers: {'Connection': 'close'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data; // Contains items, subtotals, grandTotal directly at root
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// 🎯 3. RADAR LOCATE: Acquires real-time tracking target parameters.
  Future<Map<String, dynamic>?> getLocatorDetails(String targetEpc) async {
    try {
      final response = await ApiClient.dio.get(
        'v1/rfid/locate/$targetEpc',
        options: Options(headers: {'Connection': 'close'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data; // Contains trackingStatus, frequency, name directly at root
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// 📦 4. SHIPMENT VERIFY: Submits scan list alongside invoice ID for content matching.
  Future<Map<String, dynamic>?> verifyShipment(String shipmentNo, List<String> scannedEpcs) async {
    try {
      final response = await ApiClient.dio.post(
        'v1/rfid/verify-shipment',
        data: {
          'shipmentNo': shipmentNo,
          'scannedEpcs': scannedEpcs
        },
        options: Options(headers: {'Connection': 'close'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data; // Contains matching results/discrepancies directly at root
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
