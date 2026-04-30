import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lens_retail_app_bcat/features/reports/screens/staff_performance_report_screen.dart';
import 'package:lens_retail_app_bcat/features/reports/services/report_service.dart';

// Manual Mock for ReportService
class MockReportService extends ReportService {
  @override
  Future<List<Map<String, dynamic>>> fetchStaffPerformance() async {
    // Return dummy data for testing
    return [
      {
        'staffId': '1',
        'name': 'John Doe',
        'totalTasks': 10,
        'completedTasks': 7, // Pending 3
      },
      {
        'staffId': '2',
        'name': 'Jane Smith',
        'totalTasks': 6,
        'completedTasks': 2, // Pending 4
      },
    ];
  }
}

void main() {
  testWidgets('StaffPerformanceScreen displays staff data correctly', (WidgetTester tester) async {
    // 1. Setup the mock service
    final mockService = MockReportService();

    // 2. Pump the widget
    await tester.pumpWidget(
      MaterialApp(
        home: StaffPerformanceScreen(reportService: mockService),
      ),
    );

    // 3. Wait for the data to load (since it's async)
    await tester.pump(); // Start the future
    await tester.pump(); // Rebuild after future completes

    // 4. Verify that John Doe is displayed
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Total Tasks: 10'), findsOneWidget);
    expect(find.text('7'), findsOneWidget); // Completed tasks for John
    expect(find.text('3'), findsOneWidget); // Pending tasks for John

    // 5. Verify that Jane Smith is displayed
    expect(find.text('Jane Smith'), findsOneWidget);
    expect(find.text('Total Tasks: 6'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // Completed tasks for Jane
    expect(find.text('4'), findsOneWidget); // Pending tasks for Jane

    // 6. Verify success rate calculation (Displayed twice: badge and stat item)
    expect(find.text('70%'), findsNWidgets(2));
    expect(find.text('33%'), findsNWidgets(2));
  });
}
