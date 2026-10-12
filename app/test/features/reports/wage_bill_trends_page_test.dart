import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/core/providers/services.dart';
import 'package:clearwage/core/widgets/shimmer_loading.dart';
import 'package:clearwage/data/models/report_models.dart';
import 'package:clearwage/data/services/report_service.dart';
import 'package:clearwage/features/reports/wage_bill_trends_page.dart';

class _NoOpApiClient extends ApiClient {
  _NoOpApiClient() : super(baseUrl: 'http://localhost');
}

class FakeReportService extends ReportService {
  List<WageBillTrendItem> _items = [];
  Completer<List<WageBillTrendItem>>? _pending;

  FakeReportService() : super(_NoOpApiClient());

  void setItems(List<WageBillTrendItem> items) => _items = items;
  void simulateSlow() {
    _pending = Completer<List<WageBillTrendItem>>();
  }

  void completeSlow() {
    _pending?.complete(_items);
    _pending = null;
  }

  @override
  Future<List<WageBillTrendItem>> wageBillTrends() async {
    if (_pending != null) return _pending!.future;
    return _items;
  }
}

Widget _buildApp(FakeReportService svc, {bool withData = true}) {
  svc.setItems(
    withData
        ? [
            WageBillTrendItem(month: '2026-01', totalWages: 50000),
            WageBillTrendItem(month: '2026-02', totalWages: 62000),
            WageBillTrendItem(month: '2026-03', totalWages: 58000),
          ]
        : [],
  );
  return ProviderScope(
    overrides: [reportServiceProvider.overrideWithValue(svc)],
    child: const MaterialApp(home: WageBillTrendsScreen()),
  );
}

void main() {
  testWidgets('renders chart and summary stats', (tester) async {
    final svc = FakeReportService();
    await tester.pumpWidget(_buildApp(svc));
    await tester.pumpAndSettle();

    expect(find.text('Wage Bill Trends'), findsOneWidget);
    expect(find.text('Monthly Avg'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
  });

  testWidgets('shows empty state when no trends', (tester) async {
    final svc = FakeReportService();
    await tester.pumpWidget(_buildApp(svc, withData: false));
    await tester.pumpAndSettle();

    expect(find.text('No trend data yet'), findsOneWidget);
  });

  testWidgets('shows shimmer while loading', (tester) async {
    final svc = FakeReportService();
    svc.simulateSlow();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [reportServiceProvider.overrideWithValue(svc)],
        child: const MaterialApp(home: WageBillTrendsScreen()),
      ),
    );
    await tester.pump();
    expect(find.byType(ShimmerLoading), findsOneWidget);

    svc.completeSlow();
    await tester.pumpAndSettle();
  });
}
