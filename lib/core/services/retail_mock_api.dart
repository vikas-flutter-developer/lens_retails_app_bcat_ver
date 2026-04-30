import 'dart:async';

/// A Mock Service layer to simulate Cloud API interactions.
/// Swap out these methods with real HTTP/Dio calls when your backend is ready.
class RetailMockApi {
  static final RetailMockApi _instance = RetailMockApi._internal();
  factory RetailMockApi() => _instance;
  RetailMockApi._internal();

  // Simulated Database
  final List<Map<String, dynamic>> _salesDb = [
    {'id': 'S-100', 'date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(), 'amount': 2500, 'items': 2},
    {'id': 'S-101', 'date': DateTime.now().toIso8601String(), 'amount': 1200, 'items': 1},
  ];

  // Simulated Stream for Real-Time Syncing (e.g. WebSocket representation)
  final StreamController<List<Map<String, dynamic>>> _liveSalesController = StreamController.broadcast();

  /// Expose real-time data to listeners
  Stream<List<Map<String, dynamic>>> get liveSalesStream => _liveSalesController.stream;

  /// Fetch sales with optional Date Filtering (for Reports)
  Future<List<Map<String, dynamic>>> fetchSales({DateTime? start, DateTime? end}) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Network delay

    if (start == null || end == null) return _salesDb;

    return _salesDb.where((sale) {
      final sd = DateTime.parse(sale['date']);
      return sd.isAfter(start.subtract(const Duration(days: 1))) && 
             sd.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// Create a new sale and broadcast to other devices
  Future<void> submitSale(Map<String, dynamic> saleData) async {
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate API POST
    
    // Add unique server ID
    saleData['id'] = 'S-${1000 + _salesDb.length}';
    saleData['date'] = DateTime.now().toIso8601String();
    
    _salesDb.add(saleData);
    
    // Notify all listeners of the new data (Simulating Real-Time Sync Push)
    _liveSalesController.add(_salesDb);
  }

  /// Trigger an automated background email via REST backend
  Future<bool> sendBackgroundEmailReceipt(String email, String pdfContent) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate server processing
    // In production, this would be: await dio.post('/api/send-email', data: { 'email': email, 'body': pdfContent });
    return true; 
  }

  void dispose() {
    _liveSalesController.close();
  }
}
