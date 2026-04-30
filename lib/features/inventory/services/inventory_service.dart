import '../../../core/network/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/mock/mock_data.dart';
import 'package:flutter/foundation.dart';

class InventoryService {
  Future<List<Map<String, dynamic>>> fetchInventoryAlerts() async {
    if (AppConfig.useMockData) {
      debugPrint('🧪 [InventoryService] MOCK MODE: Returning mock alerts');
      await Future.delayed(const Duration(milliseconds: 500));
      return MockData.mockInventory.where((i) => (i['stock'] as num? ?? 0) <= (i['alertQty'] as num? ?? 0)).toList();
    }
    try {
      // Calling the advanced reorder report endpoint which identifies items under alert
      final response = await ApiClient.dio.post('inventory/reorder-report', data: {});
      
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
      final response = await ApiClient.dio.get('inventory/low-stock');
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
      final response = await ApiClient.dio.get('item');
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
      final response = await ApiClient.dio.post('item/add-item', data: itemData);
      debugPrint('📥 [InventoryService] Response: ${response.statusCode} - ${response.data}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ [InventoryService] Error adding item: $e');
      return false;
    }
  }
}
