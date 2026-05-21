import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/mock/mock_data.dart';
import 'package:flutter/foundation.dart';

class LedgerService {
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
      debugPrint('📊 [LedgerService] Building ledger from collection report ($startDate to $endDate)');

      final response = await ApiClient.dio.get(
        'v1/finances/daily-summary',
        queryParameters: {'date': endDate},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data is! Map) return [];

        final entries = <Map<String, dynamic>>[];
        entries.add({
          'sn': 'CASH-IN',
          'date': endDate,
          'transType': 'Receipt',
          'vchNo': '-',
          'partyName': 'Cash Collection',
          'credit': (data['totalCashReceived'] ?? 0).toDouble(),
          'debit': 0.0,
          'balance': (data['netCashInHand'] ?? 0).toDouble(),
          'remark': 'Total cash received',
        });
        entries.add({
          'sn': 'NON-CASH',
          'date': endDate,
          'transType': 'Receipt',
          'vchNo': '-',
          'partyName': 'UPI/Bank/Card',
          'credit': (data['totalNonCashReceived'] ?? 0).toDouble(),
          'debit': 0.0,
          'balance': (data['netCashInHand'] ?? 0).toDouble(),
          'remark': 'Total non-cash received',
        });
        entries.add({
          'sn': 'EXP',
          'date': endDate,
          'transType': 'Expense',
          'vchNo': '-',
          'partyName': 'Monthly Expenses',
          'credit': 0.0,
          'debit': (data['totalExpensesPaid'] ?? 0).toDouble(),
          'balance': (data['netCashInHand'] ?? 0).toDouble(),
          'remark': 'Expenses paid',
        });
        return entries;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [LedgerService] Error fetching ledger: $e');
      if (AppConfig.useMockData) return []; // Should have hit mock block above
      rethrow;
    }
  }
}
