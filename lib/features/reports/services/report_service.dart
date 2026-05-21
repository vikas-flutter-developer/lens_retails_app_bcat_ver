import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';

class ReportService {
  Future<Map<String, dynamic>?> fetchSalesReport({String? from, String? to, String? employeeId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (from != null && from.isNotEmpty) queryParams['from'] = from;
      if (to != null && to.isNotEmpty) queryParams['to'] = to;
      if (employeeId != null && employeeId.isNotEmpty && employeeId != 'ALL') {
        queryParams['employeeId'] = employeeId;
      }

      final response = await ApiClient.dio.get('v1/reports/sales', queryParameters: queryParams);
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [ReportService] Error fetching sales report: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchFinancialSummary({String? from, String? to}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (from != null && from.isNotEmpty) queryParams['from'] = from;
      if (to != null && to.isNotEmpty) queryParams['to'] = to;

      final response = await ApiClient.dio.get('v1/reports/financial-summary', queryParameters: queryParams);
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [ReportService] Error fetching financial summary: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchStaffPerformance({String? from, String? to}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (from != null && from.isNotEmpty) queryParams['from'] = from;
      if (to != null && to.isNotEmpty) queryParams['to'] = to;

      final response = await ApiClient.dio.get('v1/reports/staff-performance', queryParameters: queryParams);
      if (response.statusCode == 200 && response.data != null) {
        final List rawData = response.data['data'] ?? [];
        return rawData.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ [ReportService] Error fetching staff performance: $e');
      return [];
    }
  }
}
