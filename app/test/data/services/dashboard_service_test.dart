import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/data/services/dashboard_service.dart';

class _FakeApiClient extends ApiClient {
  final Map<String, dynamic> _response;
  final Object? _error;
  String? lastPath;
  Map<String, String>? lastQuery;

  _FakeApiClient(this._response)
    : _error = null,
      super(baseUrl: 'http://localhost');

  _FakeApiClient.error(this._error)
    : _response = {},
      super(baseUrl: 'http://localhost');

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    lastPath = path;
    lastQuery = query;
    if (_error != null) throw _error;
    return _response;
  }
}

void main() {
  group('DashboardService.get', () {
    test('hits dashboard endpoint with default days', () async {
      final client = _FakeApiClient({
        'data': {
          'total_staff': 50,
          'present': 40,
          'absent': 5,
          'on_leave': 5,
          'attendance_percentage': 80.0,
          'daily_jama_total': 25000,
          'wage_bill_mtd': 500000,
          'total_outstanding': 100000,
          'defaulters_count': 3,
          'recent_activity': [],
          'trends': [],
        },
      });
      final svc = DashboardService(client);

      final dashboard = await svc.get();

      expect(client.lastPath, '/api/v1/dashboard');
      expect(dashboard.totalWorkforce, 50);
      expect(dashboard.presentToday, 40);
      expect(dashboard.absentToday, 5);
      expect(dashboard.onLeave, 5);
      expect(dashboard.attendancePercentage, 80.0);
      expect(dashboard.dailyJamaTotal, 25000);
      expect(dashboard.wageBillMtd, 500000);
      expect(dashboard.totalOutstanding, 100000);
      expect(dashboard.defaultersCount, 3);
    });

    test('passes custom days parameter', () async {
      final client = _FakeApiClient({
        'data': {
          'total_staff': 0,
          'present': 0,
          'absent': 0,
          'on_leave': 0,
          'recent_activity': [],
          'trends': [],
        },
      });
      final svc = DashboardService(client);

      await svc.get(trendsDays: 30);

      expect(client.lastQuery!['days'], '30');
    });

    test('returns defaults when data is empty', () async {
      final client = _FakeApiClient({});
      final svc = DashboardService(client);

      final dashboard = await svc.get();

      expect(dashboard.totalWorkforce, 0);
      expect(dashboard.recentActivity, isEmpty);
      expect(dashboard.trends, isEmpty);
    });

    test('propagates errors', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = DashboardService(client);

      expect(() => svc.get(), throwsException);
    });
  });
}
