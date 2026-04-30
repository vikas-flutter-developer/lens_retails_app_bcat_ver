import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/mock/mock_data.dart';
import '../../auth/services/auth_service.dart';
import 'package:flutter/foundation.dart';

class LedgerService {
  final AuthService _authService = AuthService();

  Future<List<Map<String, dynamic>>> fetchLedger({
    required String startDate,
    required String endDate,
  }) async {
    if (AppConfig.useMockData) {
      debugPrint('🧪 [LedgerService] MOCK MODE: Generating mock ledger entries');
      await Future.delayed(const Duration(milliseconds: 600));
      
      // Combine Orders (Sales) and Expenses into a Ledger format
      final List<Map<String, dynamic>> ledger = [];
      
      // Add mock orders as credits
      for (var order in MockData.mockOrders) {
        ledger.add({
          'sn': order['sn'],
          'date': order['date'],
          'transType': 'Sale',
          'vchNo': order['sn'],
          'partyName': order['customer'],
          'credit': double.tryParse(order['paidAmount']?.toString() ?? '0') ?? 0.0,
          'debit': 0.0,
          'balance': 0.0, // Will be calculated below
          'remark': 'Payment for ${order['id']}'
        });
      }

      // Add mock expenses as debits
      for (var exp in MockData.mockExpenses) {
        ledger.add({
          'sn': 'EXP-${exp['id']}',
          'date': exp['date'],
          'transType': 'Expense',
          'vchNo': 'VCH-${exp['id']}',
          'partyName': exp['category'],
          'credit': 0.0,
          'debit': double.tryParse(exp['amount']?.toString() ?? '0') ?? 0.0,
          'balance': 0.0,
          'remark': exp['note']
        });
      }

      // Sort by date (oldest first for running balance)
      // Note: Simple date parsing for mock
      ledger.sort((a, b) => a['date'].compareTo(b['date']));

      // Calculate running balance
      double currentBalance = 0.0;
      for (var entry in ledger) {
        currentBalance += (entry['credit'] as double) - (entry['debit'] as double);
        entry['balance'] = currentBalance;
      }

      // Reverse to show newest first for UI
      return ledger.reversed.toList();
    }

    try {
      final userId = await _authService.getUserId();
      debugPrint('📊 [LedgerService] Fetching ledger for user: $userId ($startDate to $endDate)');

      final response = await ApiClient.dio.post(
        'customer/ledger',
        data: {
          'startDate': startDate,
          'endDate': endDate,
          'customerId': userId,
        },
        options: Options(contentType: Headers.jsonContentType),
      );

      if (response.statusCode == 200) {
        final rawData = response.data;
        List<dynamic> listData = [];

        if (rawData is List) {
          listData = rawData;
        } else if (rawData is Map) {
          listData = rawData['data'] ?? rawData['ledger'] ?? rawData['result'] ?? rawData['docs'] ?? [];
        }

        return listData.map((item) => item as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ [LedgerService] Error fetching ledger: $e');
      if (AppConfig.useMockData) return []; // Should have hit mock block above
      rethrow;
    }
  }
}
