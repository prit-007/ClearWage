import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/core/api_client.dart';
import 'package:vivek_app/data/services/report_service.dart';

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
  group('ReportService.dailySummary', () {
    test('hits daily endpoint with date', () async {
      final client = _FakeApiClient({
        'data': {
          'total_workers': 50,
          'present': 40,
          'absent': 5,
          'on_leave': 5,
          'total_wage_bill': 250000,
        },
      });
      final svc = ReportService(client);

      final summary = await svc.dailySummary(date: '2026-08-15');

      expect(client.lastPath, '/api/v1/reports/daily');
      expect(client.lastQuery!['date'], '2026-08-15');
      expect(summary.totalWorkers, 50);
    });

    test('propagates errors', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = ReportService(client);

      expect(() => svc.dailySummary(date: '2026-08-15'), throwsException);
    });
  });

  group('ReportService.employeeMonthly', () {
    test('hits employee-monthly with query params', () async {
      final client = _FakeApiClient({
        'data': {'employee_id': 'emp-1', 'total_days': 22},
      });
      final svc = ReportService(client);

      final data = await svc.employeeMonthly(
        'emp-1',
        startDate: '2026-08-01',
        endDate: '2026-08-31',
      );

      expect(client.lastPath, '/api/v1/reports/employee-monthly');
      expect(client.lastQuery!['employee_id'], 'emp-1');
      expect(client.lastQuery!['start_date'], '2026-08-01');
      expect(client.lastQuery!['end_date'], '2026-08-31');
      expect(data['total_days'], 22);
    });
  });

  group('ReportService.wageBillTrends', () {
    test('hits wage-bill-trends endpoint', () async {
      final client = _FakeApiClient({
        'data': [
          {'month': '2026-07', 'total_wages': 500000},
          {'month': '2026-08', 'total_wages': 550000},
        ],
      });
      final svc = ReportService(client);

      final trends = await svc.wageBillTrends();

      expect(client.lastPath, '/api/v1/reports/wage-bill-trends');
      expect(trends, hasLength(2));
      expect(trends[0].month, '2026-07');
    });

    test('returns empty list when data is empty', () async {
      final client = _FakeApiClient({'data': []});
      final svc = ReportService(client);

      final trends = await svc.wageBillTrends();

      expect(trends, isEmpty);
    });
  });

  group('ReportService.defaulters', () {
    test('hits defaulters endpoint', () async {
      final client = _FakeApiClient({
        'data': [
          {'employee_id': 'emp-1', 'name': 'Alice', 'balance': -5000},
        ],
      });
      final svc = ReportService(client);

      final defaulters = await svc.defaulters();

      expect(client.lastPath, '/api/v1/reports/defaulters');
      expect(defaulters, hasLength(1));
      expect(defaulters[0].name, 'Alice');
    });

    test('returns empty list when data is empty', () async {
      final client = _FakeApiClient({'data': []});
      final svc = ReportService(client);

      final defaulters = await svc.defaulters();

      expect(defaulters, isEmpty);
    });
  });

  group('ReportService.attendanceTrends', () {
    test('hits attendance-trends with days param', () async {
      final client = _FakeApiClient({
        'data': [
          {'date': '2026-08-15', 'present': 40, 'absent': 5},
        ],
      });
      final svc = ReportService(client);

      final trends = await svc.attendanceTrends(days: 14);

      expect(client.lastPath, '/api/v1/reports/attendance-trends');
      expect(client.lastQuery!['days'], '14');
      expect(trends, hasLength(1));
    });

    test('uses default 30 days', () async {
      final client = _FakeApiClient({'data': []});
      final svc = ReportService(client);

      await svc.attendanceTrends();

      expect(client.lastQuery!['days'], '30');
    });
  });
}
