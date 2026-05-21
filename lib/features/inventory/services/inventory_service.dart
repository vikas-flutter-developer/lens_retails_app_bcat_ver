import '../../../core/network/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/mock/mock_data.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class InventoryService {
  Future<List<Map<String, dynamic>>> fetchInventoryAlerts() async {
    if (AppConfig.useMockData) {
      debugPrint('🧪 [InventoryService] MOCK MODE: Returning mock alerts');
      await Future.delayed(const Duration(milliseconds: 500));
      return MockData.mockInventory.where((i) => (i['stock'] as num? ?? 0) <= (i['alertQty'] as num? ?? 0)).toList();
    }
    try {
      final response = await ApiClient.dio.get('v1/inventory/alerts');
      
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data is List) {
          return data.map((item) => item as Map<String, dynamic>).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('❌ [InventoryService] Error fetching inventory alerts: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchLowStockOnly() async {
    try {
      final response = await ApiClient.dio.post('v1/inventory/reorder-report', data: {});
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data is List) {
          return data.map((item) => item as Map<String, dynamic>).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('❌ [InventoryService] Error fetching low stock: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllItems() async {
    if (AppConfig.useMockData) {
      debugPrint('🧪 [InventoryService] MOCK MODE: Returning all mock items');
      await Future.delayed(const Duration(milliseconds: 500));
      return MockData.mockInventory;
    }
    try {
      debugPrint('📡 [InventoryService] Fetching all items...');
      final response = await ApiClient.dio.get('v1/inventory');
      debugPrint('📡 [InventoryService] Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final rawData = response.data;
        debugPrint('📋 [InventoryService] RAW DATA: $rawData');
        
        final data = rawData is List ? rawData : rawData['data'] ?? [];
        if (data is List) {
          debugPrint('✅ [InventoryService] Extracted ${data.length} items');
          return data.map((item) => item as Map<String, dynamic>).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('❌ [InventoryService] Error fetching all items: $e');
      return [];
    }
  }

  Future<bool> addItem(Map<String, dynamic> itemData) async {
    try {
      debugPrint('📤 [InventoryService] Adding item: $itemData');
      final response = await ApiClient.dio.post('v1/inventory', data: itemData);
      debugPrint('📥 [InventoryService] Response: ${response.statusCode} - ${response.data}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ [InventoryService] Error adding item: $e');
      return false;
    }
  }

  Future<bool> bulkAddItems(List<Map<String, dynamic>> items) async {
    try {
      debugPrint('📤 [InventoryService] Bulk adding ${items.length} items');
      final response = await ApiClient.dio.post('v1/inventory/bulk', data: {'products': items});
      debugPrint('📥 [InventoryService] Response: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ [InventoryService] Error bulk adding: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> parsePdf(Uint8List bytes) async {
    try {
      final base64String = base64Encode(bytes);
      debugPrint('📤 [InventoryService] Sending PDF base64 for parsing...');
      final response = await ApiClient.dio.post('v1/inventory/parse-pdf', data: {
        'fileBase64': base64String,
      });
      debugPrint('📥 [InventoryService] PDF Parse Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        dynamic products;
        if (response.data != null) {
          if (response.data['data'] != null && response.data['data']['products'] != null) {
            products = response.data['data']['products'];
          } else {
            products = response.data['products'];
          }
        }
        if (products is List) {
          return products.map((item) {
            if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            return <String, dynamic>{};
          }).where((element) => element.isNotEmpty).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('❌ [InventoryService] Error parsing PDF: $e');
      rethrow;
    }
  }

  Future<bool> updateStock(String id, int adjustment, {String? reason}) async {
    try {
      final response = await ApiClient.dio.put('v1/inventory/$id', data: {
        'adjustment': adjustment,
        'reason': reason
      });
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ [InventoryService] Error updating stock: $e');
      return false;
    }
  }

  Future<bool> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      debugPrint('📤 [InventoryService] Updating product $id with: $data');
      final response = await ApiClient.dio.put('v1/inventory/$id', data: data);
      debugPrint('📥 [InventoryService] Response: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ [InventoryService] Error updating product: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getStockHistory(String id) async {
    try {
      final response = await ApiClient.dio.get('v1/inventory/$id/history');
      if (response.statusCode == 200) {
        final movements = response.data['movements'];
        if (movements is List) {
          return movements.map((m) => m as Map<String, dynamic>).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('❌ [InventoryService] Error fetching stock history: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getFIFOBatches(String id) async {
    try {
      final response = await ApiClient.dio.get('v1/inventory/$id/fifo-batches');
      if (response.statusCode == 200) {
        final batches = response.data['batches'];
        if (batches is List) {
          return batches.map((m) => m as Map<String, dynamic>).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('❌ [InventoryService] Error fetching FIFO batches: $e');
      return [];
    }
  }

  Future<int> getMaxSerial(String id) async {
    try {
      final response = await ApiClient.dio.get('v1/inventory/$id/max-serial');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        return int.tryParse(data['maxSerial']?.toString() ?? '0') ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('❌ [InventoryService] Error getting max serial: $e');
      return 0;
    }
  }

  Future<bool> registerUnits(String id, List<String> uniqueCodes) async {
    try {
      final response = await ApiClient.dio.post(
        'v1/inventory/$id/units',
        data: {'uniqueCodes': uniqueCodes}
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ [InventoryService] Error registering units: $e');
      return false;
    }
  }
  Future<Map<String, dynamic>?> getProductByQr(String qrCode) async {
    try {
      final response = await ApiClient.dio.get('v1/products/qr/$qrCode');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [InventoryService] Error in getProductByQr: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> scanUpdateInventory({
    required String qrCode,
    required String action,
    required int quantity,
    String? reason,
  }) async {
    try {
      final response = await ApiClient.dio.patch('v1/inventory/scan-update', data: {
        'qrCode': qrCode,
        'action': action,
        'quantity': quantity,
        'reason': reason ?? 'Bulk Scan Scan Update',
      });
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [InventoryService] Error in scanUpdateInventory: $e');
      return null;
    }
  }
}
