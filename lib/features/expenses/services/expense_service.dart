import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/mock/mock_data.dart';
import '../../auth/services/auth_service.dart';
import 'package:flutter/foundation.dart';

class ExpenseService {
  final AuthService _authService = AuthService();

  Future<List<Map<String, dynamic>>> fetchExpenses() async {
    if (AppConfig.useMockData) {
      debugPrint('🧪 [ExpenseService] MOCK MODE: Returning mock expenses');
      await Future.delayed(const Duration(milliseconds: 300));
      return MockData.mockExpenses;
    }
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return [];

      final response = await ApiClient.dio.get('vouchers');
      
      if (response.statusCode == 200) {
        final rawData = response.data;
        List<dynamic> listData = [];

        if (rawData is List) {
          listData = rawData;
        } else if (rawData is Map) {
          // Try common data keys
          listData = rawData['data'] ?? rawData['vouchers'] ?? rawData['result'] ?? rawData['docs'] ?? [];
        } else {
          debugPrint('⚠️ [ExpenseService] Unexpected response type: ${rawData.runtimeType}');
        }
        
        return listData.where((item) => item is Map).map((item) {
          final map = item as Map<String, dynamic>;
          // Format based on backend Voucher schema
          // Usually Voucher has date, type, amount, etc.
          final dateStr = map['date'] ?? map['createdAt'] ?? '';
          DateTime? dt;
          try { dt = DateTime.parse(dateStr); } catch (_) {}
          
          return {
            'id': map['_id']?.toString() ?? '',
            'date': dt != null ? "${dt.day}-${dt.month}-${dt.year}" : dateStr,
            'category': map['accountName'] ?? map['type'] ?? 'Misc',
            'amount': double.tryParse(map['amount']?.toString() ?? '0') ?? 0.0,
            'note': map['remark'] ?? '',
            'type': map['type'] ?? 'Payment', // Payment is usually Expense in this context
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
      );
      return;
    }
    try {
      final userId = await _authService.getUserId();
      final payload = {
        'date': DateTime.now().toIso8601String(),
        'accountName': expense['category'],
        'amount': expense['amount'],
        'remark': expense['note'],
        'type': 'Payment', // Assuming Payment type is for expenses
        'userId': userId,
      };

      final response = await ApiClient.dio.post('vouchers', data: payload);
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to save expense');
      }
    } catch (e) {
      debugPrint('❌ [ExpenseService] Error creating expense: $e');
      rethrow;
    }
  }
}
