import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/screens/statistics/statistics_screen.dart';
import 'package:vietnam_geo_dashboard/providers/statistics_provider.dart';
import '../test_helpers/mock_providers.dart';
import '../test_helpers/widget_test_utils.dart';
import '../test_helpers/screen_test_data.dart';

void main() {
  late FakeStatisticsProvider mockStatistics;

  setUp(() {
    mockStatistics = FakeStatisticsProvider();
    mockStatistics.isLoading = false;
    mockStatistics.error = null;
    mockStatistics.selectedYear = DateTime.now().year;
    mockStatistics.incidentsByMonth = {
      'Month 1': 5,
      'Month 2': 3,
      'Month 3': 8,
      'Month 6': 10,
      'Month 12': 7,
    };
    mockStatistics.incidentsByNeighborhood = {
      'P.Bến Thành': 12,
      'P.Bến Nghé': 8,
      'P.Đa Kao': 5,
      'P.Cầu Kho': 3,
    };
    mockStatistics.incidentsByStatus = {
      'Received': 10,
      'Processing': 8,
      'Completed': 15,
      'Cancelled': 3,
    };
  });

  Widget buildTestScreen({ProviderOverrides? overrides}) {
    return const StatisticsScreen();
  }

  group('StatisticsScreen', () {
    testWidgets('should render AppBar with title', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(statistics: mockStatistics),
      );

      expect(find.text('Thống kê sự cố'), findsOneWidget);
    });

    testWidgets('should show loading indicator when loading', (tester) async {
      mockStatistics.isLoading = true;

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(statistics: mockStatistics),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error state with retry button', (tester) async {
      mockStatistics.isLoading = false;
      mockStatistics.error = 'Network error occurred';

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(statistics: mockStatistics),
      );
      await tester.pumpAndSettle();

      expect(find.text('Network error occurred'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);

      // Tap retry button
      await tester.tap(find.text('Thử lại'));
      await tester.pump();
    });

    testWidgets('should render three tabs', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(statistics: mockStatistics),
      );

      expect(find.text('Theo tháng'), findsOneWidget);
      expect(find.text('Theo khu phố'), findsOneWidget);
      expect(find.text('Theo trạng thái'), findsOneWidget);

      expect(find.byIcon(Icons.calendar_month), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
      expect(find.byIcon(Icons.pie_chart), findsOneWidget);
    });

    testWidgets('should show KPI cards in monthly tab', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(statistics: mockStatistics),
      );
      await tester.pumpAndSettle();

      // Total: 10+8+15+3 = 36, Completed: 15, Processing: 8, Received: 10
      expect(find.text('Tổng sự vụ'), findsOneWidget);
      expect(find.text('36'), findsOneWidget);
      expect(find.text('Đã hoàn thành'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('Đang xử lý'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('Đang chờ'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('should show month bar chart', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(statistics: mockStatistics),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thống kê theo tháng'), findsOneWidget);

      // Check month labels (T1, T2, T3, T6, T12)
      expect(find.text('T1'), findsOneWidget);
      expect(find.text('T2'), findsOneWidget);
      expect(find.text('T3'), findsOneWidget);
      expect(find.text('T6'), findsOneWidget);
      expect(find.text('T12'), findsOneWidget);
    });

    testWidgets('should show year dropdown and allow year change', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(statistics: mockStatistics),
      );
      await tester.pumpAndSettle();

      // Year dropdown should be present
      final yearDropdown = find.byType(DropdownButton<int>);
      expect(yearDropdown, findsOneWidget);

      // Tap dropdown
      await tester.tap(yearDropdown);
      await tester.pumpAndSettle();

      // Select previous year
      final previousYear = DateTime.now().year - 1;
      await tester.tap(find.text('$previousYear').last);
      await tester.pump();

      // Verify year changed
      expect(mockStatistics.selectedYear, previousYear);
    });

    testWidgets('should show monthly detail section', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(statistics: mockStatistics),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chi tiết sự vụ theo tháng'), findsOneWidget);
      expect(find.textContaining('sự cố'), findsAtLeast(1));
    });

    testWidgets('should switch to neighborhood tab and show data', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(statistics: mockStatistics),
      );
      await tester.pumpAndSettle();

      // Tap on "Theo khu phố" tab
      await tester.tap(find.text('Theo khu phố'));
      await tester.pumpAndSettle();

      // Should show neighborhood data
      expect(find.text('Sự cố theo khu phố'), findsOneWidget);
      expect(find.text('P.Bến Thành'), findsOneWidget);
      expect(find.text('P.Bến Nghé'), findsOneWidget);

      // Total should be visible
      expect(find.text('Tổng cộng'), findsOneWidget);
    });

    testWidgets('should switch to status tab and show pie chart', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(statistics: mockStatistics),
      );
      await tester.pumpAndSettle();

      // Tap on "Theo trạng thái" tab
      await tester.tap(find.text('Theo trạng thái'));
      await tester.pumpAndSettle();

      // Should show status breakdown
      expect(find.text('Tỷ lệ trạng thái sự cố'), findsOneWidget);
      expect(find.text('Tiếp nhận'), findsAtLeast(1));
      expect(find.text('Đang xử lý'), findsAtLeast(1));
      expect(find.text('Đã hoàn thành'), findsAtLeast(1));
      expect(find.text('Đã hủy'), findsAtLeast(1));

      // Check detail section
      expect(find.text('Chi tiết trạng thái'), findsOneWidget);
      expect(find.text('36 sự vụ'), findsOneWidget);
    });

    testWidgets('should show empty state when no data', (tester) async {
      mockStatistics.incidentsByMonth = {};
      mockStatistics.incidentsByNeighborhood = {};
      mockStatistics.incidentsByStatus = {};

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(statistics: mockStatistics),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không có dữ liệu'), findsOneWidget);
    });

    testWidgets('should show rank badges in neighborhood tab', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(statistics: mockStatistics),
      );
      await tester.pumpAndSettle();

      // Tap on "Theo khu phố" tab
      await tester.tap(find.text('Theo khu phố'));
      await tester.pumpAndSettle();

      // Should show medal emojis for top 3
      expect(find.text('🥇'), findsOneWidget);
      expect(find.text('🥈'), findsOneWidget);
      expect(find.text('🥉'), findsOneWidget);
    });

    testWidgets('should show percentage in status tab', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(statistics: mockStatistics),
      );
      await tester.pumpAndSettle();

      // Tap on "Theo trạng thái" tab
      await tester.tap(find.text('Theo trạng thái'));
      await tester.pumpAndSettle();

      // Check percentages: 10/36≈28%, 8/36≈22%, 15/36≈42%, 3/36≈8%
      expect(find.text('28%'), findsOneWidget);
      expect(find.text('22%'), findsOneWidget);
      expect(find.text('42%'), findsOneWidget);
      expect(find.text('8%'), findsOneWidget);
    });

    testWidgets('should handle status tab with empty data gracefully', (
      tester,
    ) async {
      mockStatistics.incidentsByStatus = {};

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(statistics: mockStatistics),
      );
      await tester.pumpAndSettle();

      // Switch to status tab
      await tester.tap(find.text('Theo trạng thái'));
      await tester.pumpAndSettle();

      expect(find.text('Không có dữ liệu'), findsOneWidget);
    });
  });
}
