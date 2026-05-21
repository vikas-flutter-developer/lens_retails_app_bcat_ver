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
      final response = await ApiClient.dio.get('v1/customers');
      
      final List<dynamic> data = response.data is List ? response.data : (response.data['data'] ?? []);
      
      final mapped = data.map((c) => {
        'id': c['id'] ?? c['_id'],
        'name': c['fullName'] ?? c['name'] ?? c['Name'] ?? '',
        'mobile': c['phone'] ?? c['mobile'] ?? c['MobileNumber'] ?? '',
        'address': c['address'] ?? c['Address'] ?? '',
        'dob': c['dob'] ?? c['DOB'] ?? '',
        'accountId': c['phone'] ?? c['mobile'] ?? c['AccountId'] ?? ''
      }).toList();

      if (query.isEmpty) return mapped;
      return mapped.where((c) {
        final name = (c['name'] ?? '').toString().toLowerCase();
        final mobile = (c['mobile'] ?? '').toString().toLowerCase();
        final q = query.toLowerCase();
        return name.contains(q) || mobile.contains(q);
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
      final response = await ApiClient.dio.post('v1/customers', data: {
        'fullName': customerData['name'],
        'phone': customerData['mobile'],
        'address': customerData['address'],
        'dob': customerData['dob'],
      });
      if (response.data['success'] == true) {
         final data = (response.data['data'] as Map<String, dynamic>?);
         if (data == null) return null;
         return {
           ...data,
           '_id': data['_id'] ?? data['id'],
         };
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  Future<Map<String, dynamic>?> updateCustomer(String id, Map<String, dynamic> customerData) async {
    if (AppConfig.useMockData) {
      debugPrint('🧪 [CustomerService] MOCK MODE: Updating customer $id');
      await Future.delayed(const Duration(milliseconds: 300));
      return customerData;
    }
    try {
      final response = await ApiClient.dio.patch('v1/customers/$id', data: {
        'fullName': customerData['name'],
        'phone': customerData['mobile'],
        'address': customerData['address'],
        'dob': customerData['dob'],
      });
      if (response.data['success'] == true) {
         final data = (response.data['data'] as Map<String, dynamic>?);
         if (data == null) return null;
         return {
           ...data,
           '_id': data['_id'] ?? data['id'],
         };
      }
      return null;
    } catch (e) {
      debugPrint('🚨 Error updating customer: $e');
      return null;
    }
  }
}
