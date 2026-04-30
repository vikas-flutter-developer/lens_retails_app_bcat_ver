import '../../../core/network/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/mock/mock_data.dart';
import 'package:flutter/foundation.dart';

class CustomerService {
  Future<List<Map<String, dynamic>>> searchCustomers(String query) async {
    if (AppConfig.useMockData) {
      debugPrint('🧪 [CustomerService] MOCK MODE: Searching customers for "$query"');
      await Future.delayed(const Duration(milliseconds: 300));
      
      final customers = MockData.mockCustomers.map((c) => {
        'id': 'MOCK-${c['Name']}',
        'name': c['Name'],
        'mobile': c['MobileNumber'],
        'address': c['Address'],
        'dob': c['DOB'],
        'accountId': c['MobileNumber']
      }).toList();

      if (query.isEmpty) return customers;
      return customers.where((c) => c['name'].toLowerCase().contains(query.toLowerCase())).toList();
    }
    try {
      final response = await ApiClient.dio.get('accounts/getallaccounts', queryParameters: {
        'type': 'sale',
        'search': query
      });
      
      // backend returns a direct list of accounts for this endpoint
      final List<dynamic> data = response.data is List ? response.data : (response.data['data'] ?? []);
      
      return data.map((c) => {
        'id': c['_id'] ?? c['id'],
        'name': c['Name'] ?? '',
        'mobile': c['MobileNumber'] ?? '',
        'address': c['Address'] ?? '',
        'dob': c['DOB'] ?? '',
        'accountId': c['AccountId'] ?? ''
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRecentCustomers() async {
    return searchCustomers(''); // Get all sale accounts
  }

  Future<Map<String, dynamic>?> saveCustomer(Map<String, dynamic> customerData) async {
    if (AppConfig.useMockData) {
      debugPrint('🧪 [CustomerService] MOCK MODE: Saving new customer ${customerData['name']}');
      await Future.delayed(const Duration(milliseconds: 500));
      
      final newCustomer = {
        'Name': customerData['name'],
        'MobileNumber': customerData['mobile'],
        'Address': customerData['address'],
        'DOB': customerData['dob'],
      };
      
      // Add to mock list
      MockData.mockCustomers.add(newCustomer);
      
      return {
        'id': 'MOCK-${customerData['name']}',
        '_id': 'MOCK-${customerData['name']}',
        'Name': customerData['name'],
        'MobileNumber': customerData['mobile'],
        'Address': customerData['address'],
        'DOB': customerData['dob'],
      };
    }
    try {
      final response = await ApiClient.dio.post('mobile/customers', data: customerData);
      if (response.data['success'] == true) {
         return response.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
