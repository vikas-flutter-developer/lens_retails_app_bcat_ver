import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/mock/mock_data.dart';
import '../../orders/services/order_service.dart';
import '../../tasks/services/task_service.dart';
import '../../inventory/services/inventory_service.dart';

class AnalyticsService {
  Future<Map<String, dynamic>> fetchMobileDashboard() async {
    // Using var to avoid potential type casting issues in hot-reload
    final s1 = OrderService();
    final s2 = TaskService();
    final s3 = InventoryService();

    if (AppConfig.useMockData) {
      debugPrint('🧪 [AnalyticsService] MOCK MODE: Calculating real-time metrics');
      
      try {
        // Fetch real data from services
        final orders = await s1.fetchOrders();
        final tasks = await s2.fetchTasks();
        final alerts = await s3.fetchInventoryAlerts();

        // Calculate counts
        // Only count 'In Progress' for Active Jobs to match exactly 5
        final int activeJobs = orders.where((o) => o['status'] == 'In Progress').length;
        final int pendingTasks = tasks.where((t) => t['status'] == 'Pending').length;
        final int lowStock = alerts.length;

        final metrics = MockData.getDashboardMetrics();
        metrics['activeJobCards'] = activeJobs;
        metrics['pendingTasks'] = pendingTasks;
        metrics['lowStockCount'] = lowStock;

        debugPrint('📊 [AnalyticsService] Calculated: Jobs=$activeJobs, Tasks=$pendingTasks, Stock=$lowStock');
        return metrics;
      } catch (e) {
        debugPrint('⚠️ [AnalyticsService] Error calculating real-time metrics: $e');
        return MockData.getDashboardMetrics();
      }
    }
    
    try {
      debugPrint('📊 [AnalyticsService] Fetching mobile dashboard summary...');
      final response = await ApiClient.dio.get('v1/mobile/analytics/dashboard');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        debugPrint('✅ [AnalyticsService] Dashboard data: $data');
        return data is Map ? data as Map<String, dynamic> : {};
      }
      return {};
    } on DioException catch (e) {
      debugPrint('❌ [AnalyticsService] DioError: ${e.response?.statusCode} ${e.response?.data}');
      return {};
    } catch (e) {
      debugPrint('❌ [AnalyticsService] Error: $e');
      return {};
    }
  }
}
