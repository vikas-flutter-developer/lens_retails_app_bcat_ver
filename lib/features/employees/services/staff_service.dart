import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/mock/mock_data.dart';
import 'package:flutter/foundation.dart';

class StaffService {
  static const String _mockStaffKey = 'store_staff_persistence';

  Future<List<dynamic>> fetchStaff() async {
    if (AppConfig.useMockData) {
      final prefs = await SharedPreferences.getInstance();
      final String? savedStaff = prefs.getString(_mockStaffKey);
      if (savedStaff != null) {
        try {
          return jsonDecode(savedStaff);
        } catch (e) {
          debugPrint('❌ [StaffService] Error decoding staff: $e');
        }
      }
      return MockData.mockStaff;
    }
    try {
      final response = await ApiClient.dio.get('v1/employees');
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? [];
        if (data is List) {
          return data.map((s) {
            if (s is! Map) return s;
            return {
              ...s,
              '_id': s['_id'] ?? s['id'],
            };
          }).toList();
        }
        return [];
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching employees: $e');
      return [];
    }
  }

  Future<bool> createStaff(Map<String, dynamic> staffData) async {
    if (AppConfig.useMockData) {
      final String newId = DateTime.now().millisecondsSinceEpoch.toString();
      final newMember = {
        '_id': newId,
        'id': newId,
        ...staffData,
      };
      MockData.mockStaff.insert(0, newMember);
      await _saveStaffLocally(MockData.mockStaff);
      return true;
    }
    try {
      final response = await ApiClient.dio.post('v1/employees', data: staffData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error creating employee: $e');
      return false;
    }
  }

  Future<bool> updateStaff(String staffId, Map<String, dynamic> staffData) async {
    if (AppConfig.useMockData) {
      final index = MockData.mockStaff.indexWhere((s) => s['_id'].toString() == staffId);
      if (index != -1) {
        MockData.mockStaff[index] = {
          ...MockData.mockStaff[index],
          ...staffData,
        };
        await _saveStaffLocally(MockData.mockStaff);
        return true;
      }
      return false;
    }
    try {
      final response = await ApiClient.dio.put('v1/employees/$staffId', data: staffData);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating employee: $e');
      return false;
    }
  }

  Future<bool> deleteStaff(String staffId) async {
    if (AppConfig.useMockData) {
      final index = MockData.mockStaff.indexWhere((s) => s['_id'].toString() == staffId);
      if (index != -1) {
        MockData.mockStaff.removeAt(index);
        await _saveStaffLocally(MockData.mockStaff);
        return true;
      }
      return false;
    }
    try {
      final response = await ApiClient.dio.delete('v1/employees/$staffId');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting employee: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchTaskCounts(String staffId) async {
    if (AppConfig.useMockData) {
      return {
        'employeeId': staffId,
        'assigned': 3,
        'completed': 1,
        'pending': 2,
      };
    }
    try {
      final response = await ApiClient.dio.get('v1/employees/$staffId/tasks');
      if (response.statusCode == 200) {
        return response.data['data'] ?? response.data;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching task counts: $e');
      return null;
    }
  }

  Future<void> _saveStaffLocally(List<dynamic> staffList) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_mockStaffKey, jsonEncode(staffList));
      debugPrint('💾 [StaffService] Staff saved locally');
    } catch (e) {
      debugPrint('❌ [StaffService] Save failed: $e');
    }
  }
}
