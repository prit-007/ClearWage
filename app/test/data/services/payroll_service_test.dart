import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/core/api_client.dart';
import 'package:vivek_app/data/services/payroll_service.dart';

class _FakeApiClient extends ApiClient {
  final Map<String, dynamic> _response;
  final Object? _error;
  String? lastMethod;
  String? lastPath;
  Map<String, dynamic>? lastBody;

  _FakeApiClient(this._response)
    : _error = null,
      super(baseUrl: 'http://localhost');

  _FakeApiClient.error(this._error)
    : _response = {},
      super(baseUrl: 'http://localhost');

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    lastMethod = 'POST';
    lastPath = path;
    lastBody = body;
    if (_error != null) throw _error;
    return _response;
  }

  @override
  Future<List<int>> postRaw(String path, {Map<String, dynamic>? body}) async {
    lastMethod = 'POST';
    lastPath = path;
    lastBody = body;
    if (_error != null) throw _error;
    return [37, 80, 68, 70]; // %PDF
  }
}

void main() {
  group('PayrollService.calculate', () {
    test('POSTs to payroll/calculate with date range', () async {
      final client = _FakeApiClient({
        'data': {
          'total_wage': 500000,
          'entries': [
            {
              'employee_id': 'emp-1',
              'name': 'Alice',
              'gross_wages': 25000,
              'net_payable': 22000,
              'total_udhaar': 3000,
            },
          ],
        },
      });
      final svc = PayrollService(client);

      final result = await svc.calculate(
        startDate: '2026-08-01',
        endDate: '2026-08-31',
      );

      expect(client.lastMethod, 'POST');
      expect(client.lastPath, '/api/v1/payroll/calculate');
      expect(client.lastBody!['start_date'], '2026-08-01');
      expect(client.lastBody!['end_date'], '2026-08-31');
      expect(result.totalWage, 500000);
      expect(result.entries, hasLength(1));
      expect(result.entries[0].name, 'Alice');
    });

    test('handles empty entries', () async {
      final client = _FakeApiClient({
        'data': {'total_wage': 0, 'entries': []},
      });
      final svc = PayrollService(client);

      final result = await svc.calculate(
        startDate: '2026-08-01',
        endDate: '2026-08-31',
      );

      expect(result.entries, isEmpty);
      expect(result.totalWage, 0);
    });

    test('handles missing data key', () async {
      final client = _FakeApiClient({});
      final svc = PayrollService(client);

      final result = await svc.calculate(
        startDate: '2026-08-01',
        endDate: '2026-08-31',
      );

      expect(result.entries, isEmpty);
    });

    test('propagates errors', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = PayrollService(client);

      expect(
        () => svc.calculate(startDate: '2026-08-01', endDate: '2026-08-31'),
        throwsException,
      );
    });
  });

  group('PayrollService.generatePayslip', () {
    test('POSTs raw to payslip endpoint', () async {
      final client = _FakeApiClient({});
      final svc = PayrollService(client);

      final bytes = await svc.generatePayslip(
        employeeId: 'emp-1',
        startDate: '2026-08-01',
        endDate: '2026-08-31',
      );

      expect(client.lastMethod, 'POST');
      expect(client.lastPath, '/api/v1/payroll/payslip');
      expect(client.lastBody!['employee_id'], 'emp-1');
      expect(bytes, isNotEmpty);
    });
  });

  group('PayrollService.lockMonth', () {
    test('POSTs to payroll/lock with date range', () async {
      final client = _FakeApiClient({'data': {}});
      final svc = PayrollService(client);

      await svc.lockMonth(startDate: '2026-08-01', endDate: '2026-08-31');

      expect(client.lastMethod, 'POST');
      expect(client.lastPath, '/api/v1/payroll/lock');
      expect(client.lastBody!['start_date'], '2026-08-01');
      expect(client.lastBody!['end_date'], '2026-08-31');
    });

    test('includes adjustments when provided', () async {
      final client = _FakeApiClient({'data': {}});
      final svc = PayrollService(client);

      await svc.lockMonth(
        startDate: '2026-08-01',
        endDate: '2026-08-31',
        adjustments: [
          {'employee_id': 'emp-1', 'net_pay': 25000},
        ],
      );

      expect(client.lastBody!['adjustments'], hasLength(1));
    });

    test('omits adjustments when null', () async {
      final client = _FakeApiClient({'data': {}});
      final svc = PayrollService(client);

      await svc.lockMonth(startDate: '2026-08-01', endDate: '2026-08-31');

      expect(client.lastBody!.containsKey('adjustments'), false);
    });
  });
}
