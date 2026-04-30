import '../../../core/network/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/mock/mock_data.dart';
import 'package:flutter/foundation.dart';
import '../../auth/services/auth_service.dart';

class CollectionService {
  final AuthService _authService = AuthService();
  Future<Map<String, dynamic>> fetchDailySummary(DateTime date) async {
    if (AppConfig.useMockData) {
      debugPrint('🧪 [CollectionService] MOCK MODE: Returning revenue breakdown');
      await Future.delayed(const Duration(milliseconds: 400));
      return {
        'cash': MockData.cashCollection,
        'bank': MockData.bankCollection + MockData.upiCollection,
        'totalIn': MockData.totalRevenue,
        'details': {
          'CASH': MockData.cashCollection,
          'HDFC Bank': MockData.bankCollection,
          'UPI / QR': MockData.upiCollection,
        },
      };
    }
    try {
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      debugPrint('📡 [CollectionService] Fetching summary for $dateStr');
      
      final response = await ApiClient.dio.post('reports/collection', data: {
        'dateFrom': dateStr,
        'dateTo': dateStr,
        'reportBy': 'Date Wise',
        'transTypes': [
          'Sale', 'Sale Order', 'Sale Challan',
          'Purchase', 'Purchase Order', 'Purchase Challan',
          'Damage and Shrinkage', 'Receipt', 'Payment'
        ]
      });
      
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'] is List ? response.data['data'] : [];
        if (data.isNotEmpty) {
          final summary = data[0] as Map<dynamic, dynamic>;
          return {
            'cash': (summary['cashDr'] ?? 0).toDouble(),
            'bank': (summary['bankDr'] ?? 0).toDouble(),
            'totalIn': ((summary['cashDr'] ?? 0) + (summary['bankDr'] ?? 0)).toDouble(),
            'details': Map<String, dynamic>.from(summary['details'] ?? {}),
          };
        }
      }
      return {'cash': 0.0, 'bank': 0.0, 'totalIn': 0.0, 'details': <String, dynamic>{}};
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
  }) async {
    try {
      debugPrint('💰 [CollectionService] Recording receipt for $customerName ($accountId): ₹$amount');
      
      final companyId = await _authService.getCompanyId();
      if (companyId == null) throw Exception('Company ID not found');

      final retailerId = await _authService.getMongoUserId();
      final retailerName = await _authService.getUserName();

      // Construct Voucher object with Double Entry logic (aligned with dashboard filters)
      final payload = {
        'companyId': companyId,
        'recordType': 'Receipt',
        'billSeries': 'SAL_26',
        'billNo': DateTime.now().millisecondsSinceEpoch.toString().substring(7),
        'date': DateTime.now().toIso8601String(),
        'rows': [
          // Row 1: The Customer paying (Credited)
          {
            'sn': 1,
            'dc': 'C',
            'account': customerName,
            'accountId': accountId, // The Customer's ID
            'credit': amount,
            'debit': 0,
            'modeOfPayment': 'Cash',
            'shortNarration': 'Payment for Order #$orderId',
          },
          // Row 2: The Retailer receiving (Debited) - This makes it show on your dashboard!
          {
            'sn': 2,
            'dc': 'D',
            'account': 'Cash', 
            'accountId': retailerId, // The Retailer's ID (Matches req.user.id in analytics)
            'credit': 0,
            'debit': amount,
            'modeOfPayment': 'Cash',
            'shortNarration': 'Receipt from $customerName',
          }
        ],
        'totalDebit': amount,
        'totalCredit': amount,
        'remarks': 'Mobile Payment for Order #$orderId'
      };

      final response = await ApiClient.dio.post('vouchers', data: payload);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ [CollectionService] Payment recorded successfully');
        return true;
      }
      
      debugPrint('⚠️ [CollectionService] Payment recording failed with status: ${response.statusCode}');
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
      final response = await ApiClient.dio.get('vouchers');
      if (response.statusCode == 200 && response.data != null) {
        final dynamic rawData = response.data is Map ? response.data['data'] : response.data;
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
