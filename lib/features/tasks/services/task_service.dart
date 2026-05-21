import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/mock/mock_data.dart';
import 'package:flutter/foundation.dart';

class TaskService {
  static const String _mockTasksKey = 'mock_tasks_persistence';

  Future<List<dynamic>> fetchTasks() async {
    if (AppConfig.useMockData) {
      debugPrint('🧪 [TaskService] MOCK MODE: Returning ${MockData.mockTasks.length} fresh mock tasks');
      return MockData.mockTasks;
    }
    try {
      final response = await ApiClient.dio.get('v1/tasks');
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? [];
        if (data is List) {
          return data.map((t) {
            if (t is! Map) return t;
            return {
              ...t,
              '_id': t['_id'] ?? t['id'],
              'assignedTo': t['assignedTo'] ?? t['assignedToStaff'] ?? {'name': 'Unassigned'},
            };
          }).toList();
        }
        return [];
      }
      return [];
    } catch (e) {
      print('Error fetching tasks: $e');
      return [];
    }
  }

  Future<bool> updateTaskStatus(String taskId, String status) async {
    if (AppConfig.useMockData) {
      final index = MockData.mockTasks.indexWhere((t) => t['_id'].toString() == taskId);
      if (index != -1) {
        MockData.mockTasks[index]['status'] = status;
        await _saveTasksLocally(MockData.mockTasks);
        return true;
      }
      return false;
    }
    try {
      final response = await ApiClient.dio.patch(
        'v1/tasks/$taskId',
        data: {'status': status},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating task status: $e');
      return false;
    }
  }

  Future<List<dynamic>> fetchStaff() async {
    if (AppConfig.useMockData) {
      final prefs = await SharedPreferences.getInstance();
      final String? savedStaff = prefs.getString('store_staff_persistence');
      
      if (savedStaff != null) {
        try {
          return jsonDecode(savedStaff);
        } catch (e) {
          debugPrint('❌ [TaskService] Error decoding staff list: $e');
        }
      }
      return MockData.mockStaff;
    }
    try {
      final response = await ApiClient.dio.get('v1/employees/all/tasks');
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
      print('Error fetching staff: $e');
      return [];
    }
  }

  Future<bool> createTask(Map<String, dynamic> taskData) async {
    if (AppConfig.useMockData) {
      final newTask = {
        '_id': DateTime.now().millisecondsSinceEpoch.toString(),
        ...taskData,
        'assignedTo': {'name': MockData.mockStaff.firstWhere((s) => s['_id'] == taskData['assignedTo'])['name']}
      };
      MockData.mockTasks.add(newTask);
      await _saveTasksLocally(MockData.mockTasks);
      return true;
    }
    try {
      final response = await ApiClient.dio.post('v1/tasks', data: taskData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error creating task: $e');
      return false;
    }
  }

  Future<bool> updateTask(String taskId, Map<String, dynamic> taskData) async {
    if (AppConfig.useMockData) {
      final index = MockData.mockTasks.indexWhere((t) => t['_id'].toString() == taskId);
      if (index != -1) {
        String assignedName = 'Unassigned';
        try {
          assignedName = MockData.mockStaff.firstWhere((s) => s['_id'] == taskData['assignedTo'])['name'];
        } catch (_) {}
        MockData.mockTasks[index] = {
          ...MockData.mockTasks[index],
          ...taskData,
          'assignedTo': {'name': assignedName}
        };
        await _saveTasksLocally(MockData.mockTasks);
        return true;
      }
      return false;
    }
    try {
      final response = await ApiClient.dio.put(
        'v1/tasks/$taskId',
        data: taskData,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating task: $e');
      return false;
    }
  }

  Future<bool> deleteTask(String taskId) async {
    if (AppConfig.useMockData) {
      final index = MockData.mockTasks.indexWhere((t) => t['_id'].toString() == taskId);
      if (index != -1) {
        MockData.mockTasks.removeAt(index);
        await _saveTasksLocally(MockData.mockTasks);
        return true;
      }
      return false;
    }
    try {
      final response = await ApiClient.dio.delete(
        'v1/tasks/$taskId',
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting task: $e');
      return false;
    }
  }

  Future<void> _saveTasksLocally(List<Map<String, dynamic>> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_mockTasksKey, jsonEncode(tasks));
      debugPrint('💾 [TaskService] Tasks saved locally');
    } catch (e) {
      debugPrint('❌ [TaskService] Save failed: $e');
    }
  }
}
