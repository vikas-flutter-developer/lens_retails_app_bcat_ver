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
      if (isAccount) {
        // MATCH REACT: /accounts/delete/${id}
        final response = await ApiClient.dio.delete('accounts/delete/$id');
        // Match React Success Logic: res.data.success === true
        return response.data != null && response.data['success'] == true;
      } else {
        final response = await ApiClient.dio.delete('vendor/deleteVendor', queryParameters: {'id': id});
        return response.data != null && response.data['success'] == true;
      }
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
      // Build payload exactly as backend/React expects
      final accountData = {
        'Name': vendorData['name'],
        'PrintName': vendorData['printName'] ?? vendorData['name'],
        'Alias': vendorData['alias'] ?? '',
        'AccountId': vendorData['accountId'],
        'AccountType': vendorData['accountType'] ?? 'Purchase',
        'AccountDealerType': vendorData['dealerType'] ?? 'unregisterd',
        'Groups': [vendorData['group'] ?? 'Purchase Accounts'],
        'Stations': [vendorData['station'] ?? 'Local'],
        'State': vendorData['state'] ?? 'Maharashtra',
        'ContactPerson': vendorData['contactPerson'] ?? '',
        'MobileNumber': vendorData['phone'] ?? '',
        'Email': vendorData['email'] ?? '',
        'GSTIN': vendorData['gstin'] ?? '',
        'Address': vendorData['address'] ?? '',
        'OpeningBalance': {
          'balance': 0,
          'type': 'Dr',
        },
        'PreviousYearBalance': {
          'balance': 0,
          'type': 'Dr',
        },
        'EnableLoyality': 'Y',
      };

      // MATCH REACT: /accounts/add-account
      final response = await ApiClient.dio.post('accounts/add-account', data: accountData);
      // Match React Success Logic: res.data.success === true
      return response.data != null && response.data['success'] == true;
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
      // Fetch ONLY from Accounts collection (Type: Purchase) to match React perfectly
      final accountResponse = await ApiClient.dio.get('accounts/getallaccounts?type=purchase');
      List<Map<String, dynamic>> vendors = [];
      
      if (accountResponse.statusCode == 200) {
        final List<dynamic> accounts = accountResponse.data is List ? accountResponse.data : (accountResponse.data['data'] ?? []);
        for (var acc in accounts) {
          vendors.add({
            'id': acc['_id'] ?? acc['AccountId'],
            'name': acc['Name'] ?? acc['PrintName'], 
            'phone': acc['MobileNumber'] ?? acc['TelNumber'] ?? '',
            'address': acc['Address'] ?? '',
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

  Future<List<Map<String, dynamic>>> fetchItems() async {
    if (AppConfig.useMockData) {
      debugPrint('🧪 [MasterData] MOCK MODE: Returning 10 items (Lens & Frames)');
      await Future.delayed(const Duration(milliseconds: 300));
      return MockData.mockItems;
    }
    try {
      final response = await ApiClient.dio.get('items/');
      
      if (response.statusCode == 200) {
        final data = response.data;

        if (data is List) {
           return List<Map<String, dynamic>>.from(data);
        } else if (data is Map) {
           // Check multiple possible keys where the list might be stored
           dynamic listData = data['data'] ?? data['items'] ?? data['result'] ?? data['docs'];
           
           if (listData != null && listData is List) {
             return List<Map<String, dynamic>>.from(listData);
           }
        }
      }
      return [];
    } catch (e) {
      debugPrint('❌ [MasterData] Error fetching items: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchAccounts() async {
    try {
      final response = await ApiClient.dio.get('accounts/getallaccounts');
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
}
