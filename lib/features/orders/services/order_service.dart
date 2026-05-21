import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/order_status_util.dart';
import '../../../core/config/app_config.dart';
import '../../../core/mock/mock_data.dart';
import 'package:flutter/foundation.dart';

class OrderService {
  Future<List<Map<String, dynamic>>> fetchOrders() async {
    List<Map<String, dynamic>> rawOrders = [];
    if (AppConfig.useMockData) {
      rawOrders = List<Map<String, dynamic>>.from(MockData.mockOrders);
    } else {
      final response = await ApiClient.dio.get('v1/orders');
      if (response.statusCode == 200) {
        rawOrders.addAll(_extractList(response.data).cast<Map<String, dynamic>>());
      }
    }

    final mappedOrders = rawOrders.map((item) {
      final partyData = item['partyData'] ?? {};
      final billData = item['billData'] ?? {};
      final summary = item['summary'] ?? item['financials'] ?? {};
      final itemsList = item['items'] as List? ?? [];

      String formattedDate = item['date']?.toString() ?? '';
      DateTime? sortDate;
      try {
        final dateStr = billData['date'] ?? item['date'] ?? item['createdAt'];
        if (dateStr != null) {
          final dt = DateTime.parse(dateStr.toString());
          sortDate = dt;
          formattedDate = '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
        }
      } catch (_) {}

      final double computedAmount = (summary['totalAmount'] != null)
          ? double.tryParse(summary['totalAmount'].toString()) ?? 0.0
          : (double.tryParse(item['amount']?.toString() ?? item['totalAmount']?.toString() ?? '0') ??
              itemsList.fold(0.0, (sum, i) => sum + (double.tryParse(i['totalAmount']?.toString() ?? '0') ?? 0.0)));

      final double computedPaid = double.tryParse(
            item['paidAmount']?.toString() ??
                summary['paidAmount']?.toString() ??
                '0',
          ) ??
          0.0;
      final double computedDue = double.tryParse(
            item['dueAmount']?.toString() ??
                summary['dueAmount']?.toString() ??
                (computedAmount - computedPaid).toString(),
          ) ??
          (computedAmount - computedPaid);

      return {
        'sn': item['sn']?.toString() ?? billData['billNo']?.toString() ?? item['billNo']?.toString() ?? '0',
        'id': item['_id']?.toString() ?? item['id']?.toString() ?? '0',
        'customer': item['customer']?.toString() ?? item['customerName']?.toString() ?? partyData['partyAccount']?.toString() ?? 'Unknown',
        'mobile': item['mobile']?.toString() ?? item['contactNumber']?.toString() ?? partyData['contactNumber']?.toString() ?? '',
        'invoice': billData['billNo'] ?? item['billNo'] ?? item['sn'] ?? 'N/A',
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
    final items = order['items'];
    if (items != null && items is List && items.isNotEmpty) {
      for (var item in items) {
        final itemEye = item['eye'] ?? 'Both';
        if (itemEye == 'Both' || itemEye == eye) {
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
      final response = await ApiClient.dio.get('v1/orders/next-id');
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data['data'];
        if (data is Map && data['nextId'] != null) {
          return data['nextId'].toString();
        }
      }
      return 'ORD-101';
    } catch (_) {
      return 'ORD-101';
    }
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> payload) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      return {'success': true, 'data': payload};
    }
    final response = await ApiClient.dio.post('v1/orders', data: _buildBackendPayload(payload));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.data is Map<String, dynamic> ? response.data : {'success': true};
    }
    throw Exception('Failed to create order');
  }

  Future<Map<String, dynamic>> createRxOrder(Map<String, dynamic> payload) async {
    return createOrder(payload);
  }

  Future<Map<String, dynamic>> deleteOrder(String id) async {
    debugPrint('Delete API is not available for current backend: $id');
    return {'success': false, 'message': 'Delete operation is not supported by the current backend.'};
  }

  Future<Map<String, dynamic>> deleteRxOrder(String id) async {
    debugPrint('Delete API is not available for current backend: $id');
    return {'success': false, 'message': 'Delete operation is not supported by the current backend.'};
  }

  Future<Map<String, dynamic>> fetchDeliveryOtp(String orderId) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      return {'success': true, 'otp': '1234', 'isWhitelisted': false};
    }

    final candidates = [
      'v1/orders/$orderId/otp',
      'v1/orders/$orderId/delivery-otp',
      'v1/orders/$orderId',
    ];

    for (final path in candidates) {
      try {
        final resp = await ApiClient.dio.get(path);
        if ((resp.statusCode == 200 || resp.statusCode == 201) && resp.data != null) {
          final data = resp.data is Map ? Map<String, dynamic>.from(resp.data) : {'data': resp.data};
          // Normalize common shapes
          final result = <String, dynamic>{'success': true};
          if (data.containsKey('otp')) result['otp'] = data['otp'];
          if (data.containsKey('isWhitelisted')) result['isWhitelisted'] = data['isWhitelisted'];
          if (data.containsKey('data') && data['data'] is Map) {
            final inner = Map<String, dynamic>.from(data['data']);
            if (inner.containsKey('otp')) result['otp'] = inner['otp'];
            if (inner.containsKey('isWhitelisted')) result['isWhitelisted'] = inner['isWhitelisted'];
          }
          if (result.length > 1) return result;
        }
      } catch (_) {}
    }

    return {'success': false, 'message': 'Delivery OTP not available'};
  }

  Future<void> updateOrderStatus(String orderId, String type, String newStatus, {String? customerId, List<dynamic>? items}) async {
    if (AppConfig.useMockData) return;
    await ApiClient.dio.patch('v1/orders/$orderId', data: {'status': newStatus});
  }

  Future<bool> updateOrderPayment(String orderId, double paidAmount, {bool isRx = false, String paymentMode = 'Cash'}) async {
    if (AppConfig.useMockData) return true;

    final payload = {
      'amountCollected': paidAmount,
      'paymentMode': paymentMode,
      'date': DateTime.now().toIso8601String(),
    };

    final candidates = [
      'v1/orders/$orderId/payments',
      'v1/payments',
      'v1/orders/payments',
    ];

    for (final path in candidates) {
      try {
        final resp = await ApiClient.dio.post(path, data: payload);
        if (resp.statusCode == 200 || resp.statusCode == 201) return true;
      } catch (e) {
        debugPrint('⚠️ [OrderService] Payment post to $path failed: $e');
      }
    }

    return false;
  }

  Future<Map<String, dynamic>> editLensSaleOrder(String orderId, Map<String, dynamic> payload) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      return {'success': true, 'data': payload};
    }

    try {
      final dataToSend = _buildBackendPayload(payload);
      final resp = await ApiClient.dio.patch('v1/orders/$orderId', data: dataToSend);
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return resp.data is Map<String, dynamic> ? Map<String, dynamic>.from(resp.data) : {'success': true};
      }
      return {'success': false, 'message': 'Edit request failed with status ${resp.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Map<String, dynamic> _buildBackendPayload(Map<String, dynamic> payload) {
    final billData = (payload['billData'] as Map?) ?? {};
    final partyData = (payload['partyData'] as Map?) ?? {};
    final summary = (payload['summary'] as Map?) ?? {};
    final items = (payload['items'] as List?) ?? [];

    final totalAmount = double.tryParse(
          payload['netAmount']?.toString() ??
              payload['totalAmount']?.toString() ??
              summary['totalAmount']?.toString() ??
              '0',
        ) ??
        0.0;

    final paidAmount = double.tryParse(payload['paidAmount']?.toString() ?? '0') ?? 0.0;
    final dueAmount = double.tryParse(payload['dueAmount']?.toString() ?? (totalAmount - paidAmount).toString()) ?? (totalAmount - paidAmount);

    return {
      'orderType': payload['orderType'] ?? 'RX',
      'billData': {
        'billSeries': billData['billSeries'] ?? 'ORD_25-26',
        'billNo': billData['billNo'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'date': billData['date'] ?? DateTime.now().toIso8601String(),
        'bookedBy': billData['bookedBy'] ?? 'App',
        'godown': billData['godown'] ?? 'Main Branch',
      },
      'partyData': {
        'partyAccount': partyData['partyAccount'] ?? 'Unknown',
        'contactNumber': partyData['contactNumber'] ?? '',
        'address': partyData['address'] ?? '',
        'stateCode': partyData['stateCode'] ?? 'MH',
      },
      'items': items,
      'financials': {
        'subTotal': totalAmount,
        'taxAmount': 0,
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'dueAmount': dueAmount,
        'status': payload['status'] ?? 'Pending',
      },
      'remark': payload['remark'] ?? '',
      'paymentMode': payload['paymentMode'],
    };
  }
}
