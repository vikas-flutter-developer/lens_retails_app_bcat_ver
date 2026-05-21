import '../../../core/network/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/mock/mock_data.dart';
import 'package:flutter/foundation.dart';

class MasterDataService {
  Future<bool> deleteVendor(String id, {bool isAccount = false}) async {
    if (AppConfig.useMockData) {
      debugPrint('🧪 [MasterData] MOCK MODE: Deleting vendor $id');
      await Future.delayed(const Duration(milliseconds: 300));
      MockData.mockVendors.removeWhere((v) => v['id'] == id);
      return true;
    }
    try {
      final candidates = [
        'v1/vendors/$id',
        'v1/accounts/$id',
      ];
      for (final path in candidates) {
        try {
          final resp = await ApiClient.dio.delete(path);
          if (resp.statusCode == 200 || resp.statusCode == 204) return true;
        } catch (e) {
          debugPrint('⚠️ [MasterData] Delete $path failed: $e');
        }
      }
      // Endpoint not present or deletion not supported
      return false;
    } catch (e) {
      debugPrint('❌ [MasterData] Error deleting vendor: $e');
      return false;
    }
  }

  Future<bool> createVendor(Map<String, dynamic> vendorData) async {
    if (AppConfig.useMockData) {
      debugPrint('🧪 [MasterData] MOCK MODE: Creating vendor ${vendorData['name']}');
      await Future.delayed(const Duration(milliseconds: 500));
      MockData.mockVendors.add({
        'id': 'V-${DateTime.now().millisecondsSinceEpoch}',
        'name': vendorData['name'],
        'phone': vendorData['phone'] ?? '',
        'address': vendorData['address'] ?? '',
        'isAccount': true,
      });
      return true;
    }
    try {
      final payload = {
        'name': vendorData['name'],
        'printName': vendorData['printName'] ?? '',
        'accountId': vendorData['accountId'] ?? '',
        'alias': vendorData['alias'] ?? '',
        'group': vendorData['group'] ?? '',
        'station': vendorData['station'] ?? '',
        'phone': vendorData['phone'] ?? '',
        'email': vendorData['email'] ?? '',
        'accountType': vendorData['accountType'] ?? '',
        'address': vendorData['address'] ?? '',
        'dob': vendorData['dob'] ?? '',
        'gstin': vendorData['gstin'] ?? '',
        'contactPerson': vendorData['contactPerson'] ?? '',
      };

      final candidates = [
        'v1/vendors',
        'v1/accounts',
        'v1/contacts',
      ];

      for (final path in candidates) {
        try {
          final resp = await ApiClient.dio.post(path, data: payload);
          if (resp.statusCode == 200 || resp.statusCode == 201) return true;
        } catch (e) {
          debugPrint('⚠️ [MasterData] Vendor create at $path failed: $e');
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ [MasterData] Error creating account vendor: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchVendors() async {
    if (AppConfig.useMockData) {
      debugPrint('🧪 [MasterData] MOCK MODE: Returning 5 vendors');
      await Future.delayed(const Duration(milliseconds: 300));
      return MockData.mockVendors;
    }
    try {
      // Prefer dedicated vendor endpoint when available.
      final accountResponse = await ApiClient.dio.get('v1/vendors').catchError((_) => null);
      List<Map<String, dynamic>> vendors = [];
      
      if (accountResponse != null && accountResponse.statusCode == 200) {
        final List<dynamic> accounts = accountResponse.data is List ? accountResponse.data : (accountResponse.data['data'] ?? []);
        for (var acc in accounts) {
          vendors.add({
            'id': acc['id'] ?? acc['_id'],
            'name': acc['name'] ?? acc['Name'] ?? acc['PrintName'], 
            'phone': acc['phone'] ?? acc['mobile'] ?? acc['MobileNumber'] ?? acc['TelNumber'] ?? '',
            'email': acc['email'] ?? acc['Email'] ?? '',
            'group': acc['group'] ?? '',
            'gstin': acc['gstin'] ?? '',
            'address': acc['address'] ?? acc['Address'] ?? '',
            'contactPerson': acc['contactPerson'] ?? '',
            'isAccount': true, 
          });
        }
      } else {
        // Fallback to staff endpoint so dropdown remains usable.
        final fallback = await ApiClient.dio.get('v1/staff');
        final List<dynamic> staff = fallback.data is List ? fallback.data : (fallback.data['data'] ?? []);
        for (var s in staff) {
          vendors.add({
            'id': s['id'] ?? s['_id'],
            'name': s['name'] ?? 'Vendor',
            'phone': s['mobile'] ?? '',
            'address': '',
            'isAccount': true,
          });
        }
      }

      return vendors;
    } catch (e) {
      debugPrint('❌ [MasterData] Error fetching vendors: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchVendorById(String id) async {
    try {
      final response = await ApiClient.dio.get('v1/vendors/$id');
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> raw = Map<String, dynamic>.from(response.data);
        final innerData = raw['data'] ?? {};
        if (innerData is Map && innerData.containsKey('data')) {
          return Map<String, dynamic>.from(innerData['data'] ?? {});
        }
        return Map<String, dynamic>.from(innerData);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [MasterData] Error fetching vendor by id: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchVendorLedger(String id) async {
    try {
      final response = await ApiClient.dio.get('v1/vendors/$id/ledger');
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> raw = Map<String, dynamic>.from(response.data);
        final innerData = raw['data'] ?? {};
        if (innerData is Map && innerData.containsKey('data')) {
          return Map<String, dynamic>.from(innerData['data'] ?? {});
        }
        return Map<String, dynamic>.from(innerData);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [MasterData] Error fetching vendor ledger: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchItems() async {
    if (AppConfig.useMockData) {
      debugPrint('🧪 [MasterData] MOCK MODE: Returning 10 items (Lens & Frames)');
      await Future.delayed(const Duration(milliseconds: 300));
      return MockData.mockItems;
    }
    try {
      final response = await ApiClient.dio.get('v1/inventory');
      
      if (response.statusCode == 200) {
        final data = response.data;

        if (data is List) {
           return List<Map<String, dynamic>>.from(data).map((item) => {
             ...item,
             'itemName': item['itemName'] ?? item['name'] ?? 'Unknown Item',
             'salePrice': item['salePrice'] ?? item['purchasePrice'] ?? 1200.0,
             'stockQty': item['stockQty'] ?? item['stockQuantity'] ?? item['openingStockQty'] ?? 0,
             'mainCategory': () {
               final name = (item['itemName'] ?? item['name'] ?? '').toString().toLowerCase();
               if (name.contains('contact')) return 'Contact Lens';
               if (name.contains('solution') || name.contains('spray') || name.contains('wipe')) return 'Solutions';
               return item['mainCategory'] ?? item['kind'] ?? item['groupName'] ?? 'General';
             }(),
           }).toList();
        } else if (data is Map) {
           // Check multiple possible keys where the list might be stored
           dynamic listData = data['data'] ?? data['items'] ?? data['result'] ?? data['docs'];
           
           if (listData != null && listData is List) {
             return List<Map<String, dynamic>>.from(listData).map((item) => {
               ...item,
               'itemName': item['itemName'] ?? item['name'] ?? 'Unknown Item',
               'salePrice': item['salePrice'] ?? item['purchasePrice'] ?? 1200.0,
               'stockQty': item['stockQty'] ?? item['stockQuantity'] ?? item['openingStockQty'] ?? 0,
               'mainCategory': () {
                 final name = (item['itemName'] ?? item['name'] ?? '').toString().toLowerCase();
                 if (name.contains('contact')) return 'Contact Lens';
                 if (name.contains('solution') || name.contains('spray') || name.contains('wipe')) return 'Solutions';
                 return item['mainCategory'] ?? item['kind'] ?? item['groupName'] ?? 'General';
               }(),
             }).toList();
           }
        }
      }
      return [];
    } catch (e) {
      debugPrint('❌ [MasterData] Error fetching items: $e');
      return [];
    }
  }

  Future<bool> createInventoryProduct(Map<String, dynamic> productData) async {
    try {
      final response = await ApiClient.dio.post('v1/inventory', data: productData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ [MasterData] Error creating inventory product: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchLowStockAlerts() async {
    try {
      final response = await ApiClient.dio.get('v1/inventory/alerts');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('❌ [MasterData] Error fetching low stock alerts: $e');
      return [];
    }
  }

  Future<bool> updateInventoryProductQuantity(String productId, int quantity, {String? userId}) async {
    try {
      final payload = {
        'quantity': quantity,
        if (userId != null) 'userId': userId,
      };
      final response = await ApiClient.dio.put('v1/inventory/$productId', data: payload);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ [MasterData] Error updating product quantity: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchProductMovementHistory(String productId) async {
    try {
      final response = await ApiClient.dio.get('v1/inventory/$productId/history');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['movements'] is List) {
          return List<Map<String, dynamic>>.from(data['movements']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('❌ [MasterData] Error fetching product history: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchAccounts() async {
    try {
      final response = await ApiClient.dio.get('v1/customers');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('❌ [MasterData] Error fetching accounts: $e');
      return [];
    }
  }

  Future<bool> createCustomer(Map<String, dynamic> customerData) async {
    try {
      final payload = {
        'fullName': customerData['fullName'],
        'phone': customerData['phone'],
        'email': customerData['email'] ?? '',
      };
      final response = await ApiClient.dio.post('v1/customers', data: payload);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ [MasterData] Error creating customer: $e');
      return false;
    }
  }

  Future<bool> deleteCustomer(String id) async {
    try {
      final response = await ApiClient.dio.delete('v1/customers/$id');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ [MasterData] Error deleting customer: $e');
      return false;
    }
  }

  Future<bool> payVendor(String vendorId, double amount, String paymentMode, String referenceNumber) async {
    if (AppConfig.useMockData) {
      debugPrint('🧪 [MasterData] MOCK MODE: Paying vendor $vendorId with ₹$amount');
      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    }
    try {
      final payload = {
        'amount': amount,
        'paymentMode': paymentMode,
        'referenceNumber': referenceNumber,
      };
      final response = await ApiClient.dio.post('v1/vendors/$vendorId/pay', data: payload);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ [MasterData] Error calling payVendor API: $e');
      return false;
    }
  }

  Future<bool> updateVendor(String id, Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.dio.put('v1/vendors/$id', data: data);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ [MasterData] Error updating vendor: $e');
      return false;
    }
  }
}
