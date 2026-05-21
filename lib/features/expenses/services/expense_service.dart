import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/mock/mock_data.dart';
import 'package:flutter/foundation.dart';

class ExpenseService {
  Future<List<Map<String, dynamic>>> fetchExpenses({String period = '1month'}) async {
    if (AppConfig.useMockData) {
      debugPrint('🧪 [ExpenseService] MOCK MODE: Returning mock expenses');
      await Future.delayed(const Duration(milliseconds: 300));
      return MockData.mockExpenses;
    }
    try {
      final response = await ApiClient.dio.get('v1/expenses', queryParameters: {
        'period': period,
      });
      
      if (response.statusCode == 200) {
        final rawData = response.data;
        List<dynamic> listData = [];

        if (rawData is Map) {
          final dataVal = rawData['data'];
          if (dataVal is List) {
            listData = dataVal;
          } else if (dataVal is Map) {
            listData = dataVal['expenses'] ?? dataVal['data'] ?? [];
          } else if (rawData['expenses'] is List) {
            listData = rawData['expenses'];
          }
        } else if (rawData is List) {
          listData = rawData;
        } else {
          debugPrint('⚠️ [ExpenseService] Unexpected response type: ${rawData.runtimeType}');
        }
        
        return listData.where((item) => item is Map).map((item) {
          final map = item as Map<String, dynamic>;
          // Format based on backend Voucher schema
          // Usually Voucher has date, type, amount, etc.
          final dateStr = map['date'] ?? map['expenseDate'] ?? map['createdAt'] ?? '';
          DateTime? dt;
          try { dt = DateTime.parse(dateStr); } catch (_) {}
          
          return {
            'id': map['id']?.toString() ?? map['_id']?.toString() ?? '',
            'date': dt != null ? "${dt.day}-${dt.month}-${dt.year}" : dateStr,
            'category': map['category'] ?? map['title'] ?? 'Misc',
            'amount': double.tryParse(map['amount']?.toString() ?? '0') ?? 0.0,
            'note': map['note'] ?? map['notes'] ?? map['description'] ?? '',
            'paymentMode': map['paymentMode'] ?? 'CASH',
            'type': 'Payment',
          };
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ [ExpenseService] Error fetching expenses: $e');
      rethrow;
    }
  }

  Future<void> createExpense(Map<String, dynamic> expense) async {
    if (AppConfig.useMockData) {
      MockData.addExpense(
        expense['amount'],
        category: expense['category'] ?? 'Misc',
        note: expense['note'] ?? '',
        paymentMode: expense['paymentMode'] ?? 'CASH',
      );
      return;
    }
    try {
      final payload = {
        'title': expense['category'] ?? 'Misc',
        'amount': expense['amount'],
        'notes': expense['note'] ?? '',
        'paymentMode': expense['paymentMode'] ?? 'CASH',
      };

      final response = await ApiClient.dio.post('v1/expenses', data: payload);
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to save expense');
      }
    } catch (e) {
      debugPrint('❌ [ExpenseService] Error creating expense: $e');
      rethrow;
    }
  }

  Future<void> updateExpense(String id, Map<String, dynamic> expense) async {
    if (AppConfig.useMockData) {
      final idx = MockData.mockExpenses.indexWhere((ex) => (ex['id']?.toString() ?? ex['_id']?.toString()) == id);
      if (idx != -1) {
        MockData.mockExpenses[idx] = {
          ...MockData.mockExpenses[idx],
          'category': expense['category'] ?? MockData.mockExpenses[idx]['category'],
          'amount': expense['amount'] ?? MockData.mockExpenses[idx]['amount'],
          'note': expense['note'] ?? MockData.mockExpenses[idx]['note'],
          'paymentMode': expense['paymentMode'] ?? MockData.mockExpenses[idx]['paymentMode'] ?? 'CASH',
        };
      }
      return;
    }
    try {
      final payload = {
        'title': expense['category'] ?? 'Misc',
        'amount': expense['amount'],
        'notes': expense['note'] ?? '',
        'paymentMode': expense['paymentMode'] ?? 'CASH',
      };

      final response = await ApiClient.dio.put('v1/expenses/$id', data: payload);
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to update expense');
      }
    } catch (e) {
      debugPrint('❌ [ExpenseService] Error updating expense: $e');
      rethrow;
    }
  }

  Future<void> deleteExpense(String id) async {
    if (AppConfig.useMockData) {
      MockData.mockExpenses.removeWhere((ex) => (ex['id']?.toString() ?? ex['_id']?.toString()) == id);
      return;
    }
    try {
      final response = await ApiClient.dio.delete('v1/expenses/$id');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete expense');
      }
    } catch (e) {
      debugPrint('❌ [ExpenseService] Error deleting expense: $e');
      rethrow;
    }
  }
}
