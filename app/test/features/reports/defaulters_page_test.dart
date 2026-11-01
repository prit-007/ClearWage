import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/core/widgets/shimmer_loading.dart';
import 'package:clearwage/core/providers/services.dart';
import 'package:clearwage/data/models/report_models.dart';
import 'package:clearwage/data/services/report_service.dart';
import 'package:clearwage/features/reports/defaulters_page.dart';

class _NoOpApiClient extends ApiClient {
  _NoOpApiClient() : super(baseUrl: 'http://localhost');
}

class FakeReportService extends ReportService {
  List<DefaulterItem> _defaultersToReturn = [];
  Object? _defaultersError;

  FakeReportService() : super(_NoOpApiClient());

  void setDefaulters(List<DefaulterItem> defaulters) =>
      _defaultersToReturn = defaulters;
  void setDefaultersError(Object error) => _defaultersError = error;

  @override
  Future<List<DefaulterItem>> defaulters() async {
    if (_defaultersError != null) throw _defaultersError!;
    return _defaultersToReturn;
  }
}

Widget _buildApp(FakeReportService fakeService) {
  return ProviderScope(
    overrides: [reportServiceProvider.overrideWithValue(fakeService)],
    child: const MaterialApp(home: DefaultersScreen()),
  );
}

void main() {
  group('DefaultersScreen', () {
    late FakeReportService fakeService;

    setUp(() {
      fakeService = FakeReportService();
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(_buildApp(fakeService));
      expect(find.byType(ShimmerLoading), findsOneWidget);
    });

    testWidgets('shows zero defaulters empty state', (tester) async {
      fakeService.setDefaulters([]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Zero Defaulters'), findsOneWidget);
    });

    testWidgets('shows at risk count and employee names', (tester) async {
      fakeService.setDefaulters([
        DefaulterItem(
          name: 'Rahul',
          outstandingBalance: 25000,
          monthlyWage: 18000,
        ),
        DefaulterItem(
          name: 'Priya',
          outstandingBalance: 12000,
          monthlyWage: 15000,
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('2 AT RISK'), findsOneWidget);
      expect(find.text('Rahul'), findsOneWidget);
      expect(find.text('Priya'), findsOneWidget);
      expect(find.text('Fixed Wage: ₹18,000'), findsOneWidget);
      expect(find.text('Fixed Wage: ₹15,000'), findsOneWidget);
    });

    testWidgets('shows error state on fetch failure', (tester) async {
      fakeService.setDefaultersError(Exception('Server down'));
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load defaulters'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
