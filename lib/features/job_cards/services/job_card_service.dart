import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';

class JobCardService {
  Future<Map<String, dynamic>?> createJobCard(Map<String, dynamic> payload) async {
    try {
      final response = await ApiClient.dio.post('v1/job-cards', data: payload);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [JobCardService] Error creating job card: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getJobCard(String id) async {
    try {
      final response = await ApiClient.dio.get('v1/job-cards/$id');
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [JobCardService] Error fetching job card $id: $e');
      return null;
    }
  }

  Future<bool> removeItemFromJobCard(String id, String itemId) async {
    try {
      final response = await ApiClient.dio.delete('v1/job-cards/$id/items/$itemId');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ [JobCardService] Error removing item $itemId from job card $id: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> addPaymentToJobCard(String id, Map<String, dynamic> payload) async {
    try {
      final response = await ApiClient.dio.post('v1/job-cards/$id/payments', data: payload);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [JobCardService] Error adding payment to job card $id: $e');
      return null;
    }
  }

  Future<List<dynamic>?> getAllJobCards() async {
    try {
      final response = await ApiClient.dio.get('v1/job-cards');
      if (response.statusCode == 200) {
        if (response.data is List) {
          return response.data;
        } else if (response.data is Map && response.data['data'] is List) {
          return response.data['data'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ [JobCardService] Error fetching all job cards: $e');
      return null;
    }
  }

  Future<bool> deleteCompleteJobCard(String id) async {
    try {
      final response = await ApiClient.dio.delete('v1/job-cards/$id');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ [JobCardService] Error deleting job card $id: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> updateJobCard(String id, Map<String, dynamic> payload) async {
    try {
      final response = await ApiClient.dio.put('v1/job-cards/$id', data: payload);
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [JobCardService] Error updating job card $id: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> addItemToJobCard(String id, Map<String, dynamic> payload) async {
    try {
      final response = await ApiClient.dio.post('v1/job-cards/$id/items', data: payload);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [JobCardService] Error adding item to job card $id: $e');
      return null;
    }
  }

  Future<bool> deletePaymentFromJobCard(String id, String paymentId) async {
    try {
      final response = await ApiClient.dio.delete('v1/job-cards/$id/payments/$paymentId');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ [JobCardService] Error deleting payment $paymentId from job card $id: $e');
      return false;
    }
  }

  Future<List<dynamic>?> getJobCardsByCustomer(String customerId) async {
    try {
      final response = await ApiClient.dio.get('v1/job-cards/customer/$customerId');
      if (response.statusCode == 200) {
        if (response.data is List) {
          return response.data;
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ [JobCardService] Error fetching job cards for customer $customerId: $e');
      return null;
    }
  }

  Future<String?> getJobCardInvoiceHtml(String id) async {
    try {
      final response = await ApiClient.dio.get('v1/job-cards/$id/invoice');
      if (response.statusCode == 200) {
        return response.data.toString();
      }
      return null;
    } catch (e) {
      debugPrint('❌ [JobCardService] Error generating HTML invoice for job card $id: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> patchJobCardStatus(String id, String status) async {
    try {
      final response = await ApiClient.dio.patch('v1/job-cards/$id/status', data: {'status': status});
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [JobCardService] Error patching status for job card $id: $e');
      return null;
    }
  }
  Future<Map<String, dynamic>?> scanStatusUpdate({
    required String jobCardId,
    required String targetStatus,
  }) async {
    try {
      final response = await ApiClient.dio.post('v1/job-cards/scan-status', data: {
        'jobCardId': jobCardId,
        'targetStatus': targetStatus,
      });
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [JobCardService] Error in scanStatusUpdate: $e');
      return null;
    }
  }
}
