import '../../../core/network/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/mock/mock_data.dart';
import 'package:flutter/foundation.dart';

class CollectionService {
  Future<Map<String, dynamic>> fetchDailySummary(DateTime date, {bool isMonthly = false}) async {
    if (AppConfig.useMockData) {
      debugPrint('🧪 [CollectionService] MOCK MODE: Returning revenue breakdown');
      await Future.delayed(const Duration(milliseconds: 400));
      return {
        'cash': MockData.cashCollection,
        'bank': MockData.bankCollection + MockData.upiCollection,
        'totalIn': MockData.totalRevenue,
        'sales': MockData.totalRevenue,
        'purchase': MockData.totalRevenue * 0.55,
        'profit': MockData.totalRevenue * 0.45,
        'expenses': MockData.totalExpenses,
        'details': {
          'CASH': MockData.cashCollection,
          'HDFC Bank': MockData.bankCollection,
          'UPI / QR': MockData.upiCollection,
        },
      };
    }
    try {
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      debugPrint('📡 [CollectionService] Fetching summary for $dateStr, isMonthly: $isMonthly');
      
      final response = await ApiClient.dio.get(
        'v1/finances/daily-summary',
        queryParameters: {
          'date': dateStr,
          'isMonthly': isMonthly ? 'true' : 'false',
        },
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final summary = response.data['data'];
        if (summary is Map) {
          return {
            'cash': (summary['totalCashReceived'] ?? 0).toDouble(),
            'bank': (summary['totalNonCashReceived'] ?? 0).toDouble(),
            'totalIn': ((summary['totalCashReceived'] ?? 0) + (summary['totalNonCashReceived'] ?? 0)).toDouble(),
            'sales': (summary['totalSalesToday'] ?? 0).toDouble(),
            'purchase': (summary['totalPurchaseToday'] ?? 0).toDouble(),
            'profit': (summary['totalProfitToday'] ?? 0).toDouble(),
            'expenses': (summary['totalExpensesPaid'] ?? 0).toDouble(),
            'details': {
              'Cash': summary['totalCashReceived'] ?? 0,
              'Non Cash': summary['totalNonCashReceived'] ?? 0,
              'Expenses': summary['totalExpensesPaid'] ?? 0,
            },
          };
        }
      }
      return {'cash': 0.0, 'bank': 0.0, 'totalIn': 0.0, 'sales': 0.0, 'purchase': 0.0, 'profit': 0.0, 'expenses': 0.0, 'details': <String, dynamic>{}};
    } catch (e) {
      debugPrint('❌ [CollectionService] Error fetching summary: $e');
      return {'cash': 0.0, 'bank': 0.0, 'totalIn': 0.0, 'details': <String, dynamic>{}};
    }
  }

  Future<bool> recordPayment({
    required String orderId,
    required String customerName,
    String? accountId,
    required double amount,
    required String date,
    String paymentMode = 'Cash',
  }) async {
    try {
      debugPrint('💰 [CollectionService] Recording receipt for $customerName ($accountId): ₹$amount via $paymentMode');
      
      final payload = {
        'amountCollected': amount,
        'paymentMode': paymentMode,
        'date': date,
      };

      final candidates = [
        'v1/orders/$orderId/payments',
        'v1/payments',
        'v1/orders/payments',
      ];

      for (final path in candidates) {
        try {
          final response = await ApiClient.dio.post(path, data: payload);
          if (response.statusCode == 200 || response.statusCode == 201) {
            debugPrint('✅ [CollectionService] Payment recorded successfully via $path');
            return true;
          }
          debugPrint('⚠️ [CollectionService] Payment recording at $path failed with status: ${response.statusCode}');
        } catch (e) {
          debugPrint('⚠️ [CollectionService] Payment post to $path failed: $e');
        }
      }

      debugPrint('❌ [CollectionService] All payment endpoints failed');
      return false;
    } catch (e) {
      debugPrint('❌ [CollectionService] Error recording payment: $e');
      return false;
    }
  }

  Future<double> fetchDailyExpenses(DateTime date) async {
    if (AppConfig.useMockData) {
      // Calculate total for the entire month of the selected date
      return MockData.mockExpenses
          .where((ex) {
            final dateParts = ex['date'].split('-');
            if (dateParts.length != 3) return false;
            final m = int.parse(dateParts[1]);
            final y = int.parse(dateParts[2]);
            return m == date.month && y == date.year;
          })
          .fold<double>(0.0, (sum, ex) => sum + (ex['amount'] as double));
    }
    try {
      final response = await ApiClient.dio.get('v1/finances/expenses', queryParameters: {'period': '1month'});
      if (response.statusCode == 200 && response.data != null) {
        final dynamic rawData = response.data is Map ? (response.data['data'] != null ? response.data['data']['expenses'] : null) : response.data;
        if (rawData is! List) return 0.0;

        final List<dynamic> data = rawData;
        final dateStr = "${date.day}-${date.month}-${date.year}";
        
        double total = 0;
        for (var item in data) {
          if (item is Map) {
            final itemDate = item['date']?.toString() ?? '';
            if (itemDate.contains(dateStr)) {
              total += double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
            }
          }
        }
        return total;
      }
      return 0.0;
    } catch (e) {
      debugPrint('❌ [CollectionService] Error fetching expenses: $e');
      return 0.0;
    }
  }
}
