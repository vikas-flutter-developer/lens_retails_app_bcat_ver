import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/order_status_util.dart';
import '../../../core/config/app_config.dart';
import '../../../core/mock/mock_data.dart';
import '../../auth/services/auth_service.dart';
import 'package:flutter/foundation.dart';

class OrderService {
  final AuthService _authService = AuthService();

  Future<List<Map<String, dynamic>>> fetchOrders() async {
    List<Map<String, dynamic>> rawOrders = [];
    if (AppConfig.useMockData) {
      debugPrint('🧪 [OrderService] MOCK MODE: Returning mock orders');
      rawOrders = List<Map<String, dynamic>>.from(MockData.mockOrders);
    } else {
      try {
        final userId = await _authService.getUserId();
        if (userId == null) return [];

        final responses = await Future.wait([
          ApiClient.dio.get('lensSaleOrder/getAllLensSaleOrder', queryParameters: {'customerId': userId}),
          ApiClient.dio.get('rxSaleOrder/getAllRxSaleOrder', queryParameters: {'customerId': userId}).catchError((e) => Response(requestOptions: RequestOptions(), statusCode: 404, data: [])),
        ]);

        if (responses[0].statusCode == 200) rawOrders.addAll(_extractList(responses[0].data).cast<Map<String, dynamic>>());
        if (responses[1].statusCode == 200) rawOrders.addAll(_extractList(responses[1].data).cast<Map<String, dynamic>>());
      } catch (e) {
        debugPrint('❌ [OrderService] Error fetching orders: $e');
        rethrow;
      }
    }

    final mappedOrders = rawOrders.map((item) {
        final partyData = item['partyData'] ?? {};
        final billData = item['billData'] ?? {};
        final summary = item['summary'] ?? {};
        final itemsList = item['items'] as List? ?? [];

        // Date Logic
        String formattedDate = item['date'] ?? '';
        DateTime? sortDate;
        try {
           final dateStr = billData['date'] ?? item['date'] ?? item['createdAt'];
           if (dateStr != null) {
             final dt = DateTime.parse(dateStr);
             sortDate = dt;
             formattedDate = "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}";
           }
        } catch (_) {}

        final double computedAmount = (summary['totalAmount'] != null)
            ? double.tryParse(summary['totalAmount'].toString()) ?? 0.0
            : (double.tryParse(item['amount']?.toString() ?? '0') ?? 
               itemsList.fold(0.0, (sum, i) => sum + (double.tryParse(i['totalAmount']?.toString() ?? '0') ?? 0.0)));

        final double computedPaid = double.tryParse(item['paidAmount']?.toString() ?? summary['paidAmount']?.toString() ?? '0') ?? 0.0;
        final double computedDue = double.tryParse(item['dueAmount']?.toString() ?? summary['dueAmount']?.toString() ?? (computedAmount - computedPaid).toString()) ?? (computedAmount - computedPaid);

        return {
             'sn': item['sn']?.toString() ?? billData['billNo']?.toString() ?? '0',
             'id': item['_id']?.toString() ?? item['id']?.toString() ?? '0',
             'customer': item['customer']?.toString() ?? partyData['partyAccount']?.toString() ?? 'Unknown',
             'mobile': item['mobile']?.toString() ?? partyData['contactNumber']?.toString() ?? '',
             'invoice': billData['billNo'] ?? item['sn'] ?? 'N/A',
             'date': formattedDate,
             'sortDate': sortDate,
             'status': item['orderStatus'] ?? item['status'] ?? 'Pending',
             'amount': computedAmount.toStringAsFixed(2),
             'paidAmount': computedPaid.toStringAsFixed(2),
             'dueAmount': computedDue.toStringAsFixed(2),
             'itemsLength': itemsList.length.toString(),
             'eye_r': _extractEyeData(item, 'R'),
             'eye_l': _extractEyeData(item, 'L'),
             'type': item['orderType'] ?? item['type'] ?? 'RX',
             'remarks': item['remark'] ?? item['remarks'] ?? '',
             'raw': item,
             'items': itemsList,
        };
    }).toList();

    mappedOrders.sort(OrderStatusUtil.compareOrders);
    return mappedOrders;
  }

  List<dynamic> _extractList(dynamic rawData) {
    if (rawData is List) return rawData;
    if (rawData is Map<String, dynamic>) {
      return rawData['data'] ?? rawData['orders'] ?? rawData['result'] ?? rawData['docs'] ?? [];
    }
    return [];
  }

  Map<String, String> _extractEyeData(Map<String, dynamic> order, String eye) {
    // Basic extraction from first item found matching the eye side
    final items = order['items'];
    if (items != null && items is List && items.isNotEmpty) {
      for (var item in items) {
        // Check if item applies to this eye (RL means both)
        final itemEye = item['eye'] ?? 'RL';
        if (itemEye == 'RL' || itemEye == eye) {
           return {
             'sph': item['sph']?.toString() ?? '',
             'cyl': item['cyl']?.toString() ?? '',
             'axis': item['axis']?.toString() ?? '',
             'add': item['add']?.toString() ?? '',
           };
        }
      }
    }
    return {'sph': '', 'cyl': '', 'axis': '', 'add': ''};
  }

  Future<String> fetchNextOrderId() async {
    try {
      final orders = await fetchOrders();
      if (orders.isEmpty) return '1';

      int maxId = 0;
      for (var order in orders) {
        // Try parsing 'invoice' or 'sn' to find the highest number
        // 'invoice' usually maps to billNo, 'sn' to _id
        int? idVal;
        
        // Try invoice first (e.g. "2878")
        if (order['invoice'] != null) {
          idVal = int.tryParse(order['invoice'].toString());
        }
        
        // Fallback to SN if invoice is not a number
        if (idVal == null && order['sn'] != null) {
           idVal = int.tryParse(order['sn'].toString());
        }

        if (idVal != null && idVal > maxId) {
          maxId = idVal;
        }
      }
      return (maxId + 1).toString();
    } catch (e) {
      debugPrint('⚠️ [OrderService] Failed to calculate next ID: $e');
      return '1';
    }
  }

  /// Creates a new lens purchase order
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> payload) async {
    if (AppConfig.useMockData) {
      debugPrint('🧪 [OrderService] MOCK MODE: Creating mock order');
      await Future.delayed(const Duration(milliseconds: 800));
      final newOrder = Map<String, dynamic>.from(payload);
      
      // Calculate total amount to update metrics
      double amount = 0;
      if (newOrder['summary'] != null) {
        amount = double.tryParse(newOrder['summary']['totalAmount']?.toString() ?? '0') ?? 0.0;
      } else if (newOrder['items'] != null && newOrder['items'] is List) {
        amount = (newOrder['items'] as List).fold(0.0, (sum, i) => sum + (double.tryParse(i['totalAmount']?.toString() ?? '0') ?? 0.0));
      }
      
      if (amount > 0) MockData.addSale(amount);

      // Add to session list so it shows in Job Cards / Orders list
      MockData.mockOrders.insert(0, {
        "id": "MOCK-${DateTime.now().millisecondsSinceEpoch}",
        "customer": payload['partyData']?['partyAccount'] ?? "New Customer",
        "status": "Pending",
        "amount": amount,
        "date": DateTime.now().toString(),
        "sn": "JC/${DateTime.now().year}/${MockData.mockOrders.length + 1}",
        "type": "Single Finish"
      });
      
      return {'success': true, 'data': newOrder};
    }
    try {
      debugPrint('📦 [OrderService] Creating order. Endpoint: api/lensSaleOrder/createLensSaleOrder');
      
      // Inject User Identity
      final userId = await _authService.getUserId();
      if (userId != null) {
        payload['userId'] = userId;
      }
      
      // import convert for jsonEncode to see valid json in logs
      debugPrint('📦 [OrderService] Payload: $payload'); 

      final response = await ApiClient.dio.post(
        'lensSaleOrder/createLensSaleOrder',
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ [OrderService] Order created successfully: ${response.data}');
        return response.data is Map ? response.data : {'success': true};
      } else {
        throw Exception('Failed to create order: Status ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('❌ [OrderService] DioException: ${e.message}');
      debugPrint('❌ [OrderService] Status Code: ${e.response?.statusCode}');
      debugPrint('❌ [OrderService] Response Body: ${e.response?.data}');
      
      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final body = e.response?.data;
        
        if (statusCode == 401) {
          debugPrint('🔒 [OrderService] AUTHENTICATION FAILED - Token/Cookie not valid');
          throw Exception('Authentication failed. Please login again.');
        } else if (statusCode == 400) {
          debugPrint('⚠️ [OrderService] BAD REQUEST - Payload structure is wrong');
          throw Exception('Bad request: ${body?['message'] ?? body}');
        } else if (statusCode == 500) {
          debugPrint('💥 [OrderService] SERVER ERROR - Backend crashed');
          throw Exception('Server error. Please try again later.');
        } else {
          throw Exception('Error $statusCode: ${body?['message'] ?? 'Unknown error'}');
        }
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('❌ [OrderService] Error creating order: $e');
      rethrow;
    }
  }

  /// Creates a new RX lens sale order
  Future<Map<String, dynamic>> createRxOrder(Map<String, dynamic> payload) async {
    if (AppConfig.useMockData) {
      debugPrint('🧪 [OrderService] MOCK MODE: Creating mock RX order');
      await Future.delayed(const Duration(milliseconds: 800));
      final newOrder = Map<String, dynamic>.from(payload);
      
      // Calculate total amount to update metrics
      double amount = 0;
      if (newOrder['summary'] != null) {
        amount = double.tryParse(newOrder['summary']['totalAmount']?.toString() ?? '0') ?? 0.0;
      } else if (newOrder['items'] != null && newOrder['items'] is List) {
        amount = (newOrder['items'] as List).fold(0.0, (sum, i) => sum + (double.tryParse(i['totalAmount']?.toString() ?? '0') ?? 0.0));
      } else {
        // Fallback for RX structure
        amount = double.tryParse(newOrder['totalAmount']?.toString() ?? '0') ?? 0.0;
      }

      // For RX: Total goes to Revenue, but only Advance goes to Cash in Hand
      double advance = double.tryParse(newOrder['paidAmount']?.toString() ?? '0') ?? 0.0;
      double balance = amount - advance;
      
      if (amount > 0) {
        // totalRevenue += total, cashInHand += advance
        MockData.totalRevenue += amount;
        MockData.cashInHand += advance;
        MockData.cashCollection += advance;
        debugPrint('💰 [MockData] RX Sale: Total ₹$amount, Advance ₹$advance added to Cash. New Revenue: ₹${MockData.totalRevenue}');
      }

      final mockEntry = {
        "id": "RX-${100 + MockData.mockOrders.length}",
        "customer": payload['partyData']?['partyAccount'] ?? "New Customer",
        "mobile": payload['partyData']?['contactNumber'] ?? "",
        "status": "Pending",
        "amount": amount,
        "paidAmount": advance,
        "dueAmount": balance,
        "date": DateFormat('yyyy-MM-dd').format(DateTime.now()),
        "sn": "JC/${DateTime.now().year}/${MockData.mockOrders.length + 1}",
        "type": "RX"
      };

      MockData.mockOrders.insert(0, mockEntry);
      return {'success': true, 'data': mockEntry};
    }
    try {
      debugPrint('📦 [OrderService] Creating RX order. Endpoint: api/rxSaleOrder/createRxSaleOrder');
      
      // Inject User Identity
      final userId = await _authService.getUserId();
      if (userId != null) {
        payload['userId'] = userId;
      }

      debugPrint('📦 [OrderService] Payload: $payload'); 

      final response = await ApiClient.dio.post(
        'rxSaleOrder/createRxSaleOrder',
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ [OrderService] RX Order created successfully: ${response.data}');
        return response.data is Map ? response.data : {'success': true};
      } else {
        throw Exception('Failed to create RX order: Status ${response.statusCode}');

      }
    } on DioException catch (e) {
      debugPrint('❌ [OrderService] DioException (RX): ${e.message}');
      debugPrint('❌ [OrderService] Status Code: ${e.response?.statusCode}');
      debugPrint('❌ [OrderService] Response Body: ${e.response?.data}');
      
      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final body = e.response?.data;
        
        if (statusCode == 401) {
          throw Exception('Authentication failed. Please login again.');
        } else if (statusCode == 400) {
          throw Exception('Bad request: ${body?['message'] ?? body}');
        } else if (statusCode == 500) {
          throw Exception('Server error. Please try again later.');
        } else {
          throw Exception('Error $statusCode: ${body?['message'] ?? 'Unknown error'}');
        }
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('❌ [OrderService] Error creating RX order: $e');
      rethrow;
    }
  }

  /// Deletes a regular lens sale order
  Future<void> deleteOrder(String id) async {
    try {
      debugPrint('🗑️ [OrderService] Deleting Lens Sale Order: $id');
      
      // Try lensSaleOrder endpoint first
      try {
        final response = await ApiClient.dio.delete('lensSaleOrder/deleteLensSaleOrder/$id');
        if (response.statusCode == 200 || response.statusCode == 204) {
          debugPrint('✅ [OrderService] Deleted via lensSaleOrder endpoint');
          return;
        }
      } on DioException catch (e) {
        if (e.response?.statusCode != 404) {
          debugPrint('❌ [OrderService] lensSaleOrder delete failed: ${e.response?.statusCode} - ${e.message}');
          rethrow;
        }
        debugPrint('⚠️ [OrderService] lensSaleOrder delete failed with 404, trying saleOrder fallback...');
      }
      
      // Fallback: Try generic saleOrder endpoint
      debugPrint('🗑️ [OrderService] Attempting delete via saleOrder: $id');
      final response = await ApiClient.dio.delete('saleOrder/deleteSaleOrder/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete order. Status: ${response.statusCode}');
      }
      debugPrint('✅ [OrderService] Deleted via saleOrder fallback');
    } catch (e) {
      debugPrint('❌ [OrderService] Error deleting order: $e');
      rethrow;
    }
  }

  /// Deletes an RX sale order
  Future<void> deleteRxOrder(String id) async {
    try {
      debugPrint('🗑️ [OrderService] Attempting to delete RX Order via rxSaleOrder: $id');
      try {
        final response = await ApiClient.dio.delete('rxSaleOrder/deleteRxSaleOrder/$id');
        if (response.statusCode == 200 || response.statusCode == 204) {
          debugPrint('✅ [OrderService] Deleted via rxSaleOrder');
          return;
        }
      } on DioException catch (e) {
        if (e.response?.statusCode != 404) rethrow;
        debugPrint('⚠️ [OrderService] rxSaleOrder delete failed with 404, trying rxSale fallback...');
      }

      // Fallback: Some RX entries might belong to rxSale endpoint
      debugPrint('🗑️ [OrderService] Attempting to delete RX Order via rxSale: $id');
      final response = await ApiClient.dio.delete('rxSale/deleteRxSale/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
         throw Exception('Failed to delete RX order. Status: ${response.statusCode}');
      }
      debugPrint('✅ [OrderService] Deleted via rxSale fallback');
    } catch (e) {
      debugPrint('❌ [OrderService] Error deleting RX order: $e');
      rethrow;
    }
  }

  /// Fetches delivery OTP or Whitelist status for an order
  Future<Map<String, dynamic>> fetchDeliveryOtp(String orderId) async {
    try {
      debugPrint('🔑 [OrderService] Fetching OTP for Order: $orderId');
      final response = await ApiClient.dio.get('delivery/order/$orderId/otp');
      
      if (response.statusCode == 200) {
        debugPrint('✅ [OrderService] OTP data: ${response.data}');
        return response.data is Map ? response.data as Map<String, dynamic> : {};
      } else {
        throw Exception('Failed to fetch OTP: Status ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('❌ [OrderService] OTP Fetch DioError: ${e.response?.statusCode} ${e.response?.data}');
      if (e.response?.statusCode == 404) {
         return {}; // Order not in delivery phase yet
      }
      rethrow;
    } catch (e) {
      debugPrint('❌ [OrderService] OTP Fetch error: $e');
      rethrow;
    }
  }

  /// Updates only the status of an order (RX or regular)
  Future<void> updateOrderStatus(String orderId, String type, String newStatus, {String? customerId, List<dynamic>? items}) async {
    debugPrint('📦 [OrderService] updateOrderStatus: id=$orderId type=$type → $newStatus');
    try {
      if (AppConfig.useMockData) {
        final index = MockData.mockOrders.indexWhere((o) => o['id'] == orderId);
        if (index != -1) {
          final order = MockData.mockOrders[index];
          final oldStatus = order['status'];
          order['status'] = newStatus;

          // Auto-collect balance on Delivery
          if (newStatus == 'Delivered' && oldStatus != 'Delivered') {
            final double balance = double.tryParse(order['dueAmount']?.toString() ?? '0') ?? 0.0;
            if (balance > 0) {
              MockData.addSale(balance, mode: 'Cash');
              final double totalPaid = (double.tryParse(order['paidAmount']?.toString() ?? '0') ?? 0.0) + balance;
              order['paidAmount'] = totalPaid.toString();
              order['dueAmount'] = "0.0";
              debugPrint('💰 [MockData] Auto-collected balance ₹$balance on Delivery for $orderId');
            }
          }
          debugPrint('🧪 [MockData] Order $orderId status updated to $newStatus locally');
        }
      }

      final payload = {'status': newStatus};
      Response response;
      
      if (type == 'RX') {
        // Use the dedicated status patch endpoint for RX
        response = await ApiClient.dio.patch('rxSaleOrder/updateStatus/$orderId', data: payload);
      } else {
        // Use the dedicated status patch endpoint for regular orders
        response = await ApiClient.dio.patch('lensSaleOrder/updateStatus/$orderId', data: payload);
      }
      
      debugPrint('✅ [OrderService] Status updated successfully: ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('❌ [OrderService] Status update DioError: ${e.response?.statusCode} ${e.response?.data}');
      // In Mock Mode, we don't throw on error so the flow continues
      if (!AppConfig.useMockData) {
        throw Exception(e.response?.data is Map ? (e.response?.data['message']?.toString() ?? 'Failed: ${e.response?.statusCode}') : 'Failed: ${e.response?.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [OrderService] Status update error: $e');
      if (!AppConfig.useMockData) rethrow;
    }
  }

  /// Updates the paid amount of an order
  Future<void> updateOrderPayment(String orderId, double paidAmount, {bool isRx = false}) async {
    try {
      final endpoint = isRx ? 'rxSaleOrder/editRxSaleOrder' : 'lensSaleOrder/editLensSaleOrder';
      debugPrint('📦 [OrderService] Updating payment for ${isRx ? "RX" : "Regular"} order $orderId: ₹$paidAmount');
      
      final response = await ApiClient.dio.put(
        '$endpoint/$orderId',
        data: {'paidAmount': paidAmount},
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ [OrderService] Order payment updated successfully');
      } else {
        debugPrint('⚠️ [OrderService] Order payment update returned status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [OrderService] Error updating order payment: $e');
    }
  }

  /// Updates an existing lens sale order
  Future<Map<String, dynamic>> editLensSaleOrder(String orderId, Map<String, dynamic> payload) async {
    try {
      debugPrint('📦 [OrderService] Editing order: $orderId');
      debugPrint('📦 [OrderService] Payload: $payload');

      final response = await ApiClient.dio.put(
        'lensSaleOrder/editLensSaleOrder/$orderId',
        data: payload,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [OrderService] Order updated successfully: ${response.data}');
        return response.data is Map ? response.data : {'success': true};
      } else {
        throw Exception('Failed to update order: Status ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('❌ [OrderService] DioException (Edit): ${e.message}');
      if (e.response != null) {
        debugPrint('❌ [OrderService] Edit Response: ${e.response?.data}');
        throw Exception(e.response?.data['message'] ?? 'Failed to update order');
      }
      rethrow;
    } catch (e) {
      debugPrint('❌ [OrderService] Error updating order: $e');
      rethrow;
    }
  }
}
