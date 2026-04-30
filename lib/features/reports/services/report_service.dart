import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/network/api_client.dart';

class ReportService {
  Future<List<Map<String, dynamic>>> fetchStaffPerformance() async {
    // Check local persistence for real staff first
    final prefs = await SharedPreferences.getInstance();
    final String? savedStaffJson = prefs.getString('store_staff_persistence');
    List<dynamic> realStaff = [];

    if (savedStaffJson != null) {
      try {
        realStaff = jsonDecode(savedStaffJson);
      } catch (e) {
        debugPrint('❌ [ReportService] Error decoding real staff: $e');
      }
    }

    if (realStaff.isEmpty) {
      realStaff = MockData.mockStaff;
    }

    // FOR MOCK MODE: Assigning productivity data to REAL staff
    if (kDebugMode) {
      debugPrint('🧪 [ReportService] MOCK MODE: Mapping performance to ${realStaff.length} real staff members');
      
      return realStaff.map((staff) {
        final String name = staff['name'] ?? 'Unknown';
        // Generate deterministic but realistic mock stats for each staff
        final int hash = name.hashCode.abs();
        final int total = 10 + (hash % 20);
        final int completed = (total * 0.7 + (hash % 5)).toInt().clamp(0, total);
        
        return {
          'name': name,
          'totalTasks': total,
          'completedTasks': completed,
          'successRate': total > 0 ? completed / total : 0.0,
        };
      }).toList();
    }

    try {
      final response = await ApiClient.dio.get('tasks/reports/staff-productivity');
      
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data is List) {
          return data.map((item) => item as Map<String, dynamic>).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('❌ [ReportService] Error fetching staff performance: $e');
      return [];
    }
  }
}
