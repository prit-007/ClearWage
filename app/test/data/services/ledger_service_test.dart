import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/core/api_client.dart';
import 'package:vivek_app/data/services/ledger_service.dart';

class _FakeApiClient extends ApiClient {
  final Map<String, dynamic> _response;
  final Object? _error;
  String? lastMethod;
  String? lastPath;
  Map<String, dynamic>? lastQuery;
  Map<String, dynamic>? lastBody;

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
    lastMethod = 'GET';
    lastPath = path;
    lastQuery = query;
    if (_error != null) throw _error;
    return _response;
  }

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
}

void main() {
  group('LedgerService.listByTenant', () {
    test('parses list of ledger entries from API response', () async {
      final client = _FakeApiClient({
        'data': [
          {
            'id': 'led-1',
            'employee_id': 'emp-1',
            'employee_name': 'Alice',
            'date': '2026-08-01',
            'type': 'jama',
            'amount': 5000,
          },
          {
            'id': 'led-2',
            'employee_id': 'emp-2',
            'employee_name': 'Bob',
            'date': '2026-08-02',
            'type': 'udhaar',
            'amount': 2000,
            'note': 'Advance',
          },
        ],
      });
      final svc = LedgerService(client);

      final entries = await svc.listByTenant(
        startDate: '2026-08-01',
        endDate: '2026-08-31',
      );

      expect(entries, hasLength(2));
      expect(entries[0].employeeName, 'Alice');
      expect(entries[0].isJama, true);
      expect(entries[1].employeeName, 'Bob');
      expect(entries[1].isUdhaar, true);
      expect(entries[1].note, 'Advance');
    });

    test('returns empty list when data is empty', () async {
      final client = _FakeApiClient({'data': []});
      final svc = LedgerService(client);

      final entries = await svc.listByTenant(
        startDate: '2026-08-01',
        endDate: '2026-08-31',
      );

      expect(entries, isEmpty);
    });

    test('returns empty list when data key is missing', () async {
      final client = _FakeApiClient({});
      final svc = LedgerService(client);

      final entries = await svc.listByTenant(
        startDate: '2026-08-01',
        endDate: '2026-08-31',
      );

      expect(entries, isEmpty);
    });

    test('sends correct query parameters', () async {
      final client = _FakeApiClient({'data': []});
      final svc = LedgerService(client);

      await svc.listByTenant(
        startDate: '2026-08-01',
        endDate: '2026-08-15',
        limit: 10,
        offset: 20,
      );

      expect(client.lastMethod, 'GET');
      expect(client.lastPath, '/api/v1/ledger');
      expect(client.lastQuery!['start_date'], '2026-08-01');
      expect(client.lastQuery!['end_date'], '2026-08-15');
      expect(client.lastQuery!['limit'], '10');
      expect(client.lastQuery!['offset'], '20');
    });

    test('omits limit and offset when null', () async {
      final client = _FakeApiClient({'data': []});
      final svc = LedgerService(client);

      await svc.listByTenant(startDate: '2026-08-01', endDate: '2026-08-31');

      expect(client.lastQuery!.containsKey('limit'), false);
      expect(client.lastQuery!.containsKey('offset'), false);
    });

    test('propagates API errors', () async {
      final client = _FakeApiClient.error(Exception('Network error'));
      final svc = LedgerService(client);

      expect(
        () => svc.listByTenant(startDate: '2026-08-01', endDate: '2026-08-31'),
        throwsException,
      );
    });
  });

  group('LedgerService.listByEmployee', () {
    test('hits correct endpoint with employee ID', () async {
      final client = _FakeApiClient({'data': []});
      final svc = LedgerService(client);

      await svc.listByEmployee(
        'emp-123',
        startDate: '2026-08-01',
        endDate: '2026-08-31',
      );

      expect(client.lastPath, '/api/v1/ledger/emp-123');
    });

    test('parses entries for a specific employee', () async {
      final client = _FakeApiClient({
        'data': [
          {
            'id': 'led-10',
            'employee_id': 'emp-123',
            'employee_name': 'Charlie',
            'date': '2026-08-05',
            'type': 'jama',
            'amount': 8000,
          },
        ],
      });
      final svc = LedgerService(client);

      final entries = await svc.listByEmployee(
        'emp-123',
        startDate: '2026-08-01',
        endDate: '2026-08-31',
      );

      expect(entries, hasLength(1));
      expect(entries[0].employeeId, 'emp-123');
    });
  });

  group('LedgerService.getSummary', () {
    test('parses summary correctly', () async {
      final client = _FakeApiClient({
        'data': {
          'jama_total': 100000,
          'udhaar_total': 30000,
          'net_balance': 70000,
          'total_outstanding': 25000,
          'entry_count': 50,
        },
      });
      final svc = LedgerService(client);

      final summary = await svc.getSummary(
        startDate: '2026-08-01',
        endDate: '2026-08-31',
      );

      expect(summary.jamaTotal, 100000);
      expect(summary.udhaarTotal, 30000);
      expect(summary.netBalance, 70000);
      expect(summary.totalOutstanding, 25000);
      expect(summary.entryCount, 50);
    });

    test('sends correct query parameters', () async {
      final client = _FakeApiClient({'data': <String, dynamic>{}});
      final svc = LedgerService(client);

      await svc.getSummary(startDate: '2026-07-01', endDate: '2026-07-31');

      expect(client.lastMethod, 'GET');
      expect(client.lastPath, '/api/v1/ledger/summary');
      expect(client.lastQuery!['start_date'], '2026-07-01');
      expect(client.lastQuery!['end_date'], '2026-07-31');
    });
  });

  group('LedgerService.getBalance', () {
    test('returns balance value', () async {
      final client = _FakeApiClient({
        'data': {'balance': -15000},
      });
      final svc = LedgerService(client);

      final balance = await svc.getBalance('emp-5');

      expect(balance, -15000);
    });

    test('returns 0 when balance is missing', () async {
      final client = _FakeApiClient({'data': <String, dynamic>{}});
      final svc = LedgerService(client);

      final balance = await svc.getBalance('emp-5');

      expect(balance, 0);
    });

    test('hits correct endpoint', () async {
      final client = _FakeApiClient({
        'data': {'balance': 0},
      });
      final svc = LedgerService(client);

      await svc.getBalance('emp-99');

      expect(client.lastPath, '/api/v1/ledger/emp-99/balance');
    });
  });

  group('LedgerService.settleAccount', () {
    test('posts to settle endpoint with today date', () async {
      final client = _FakeApiClient({'data': {}});
      final svc = LedgerService(client);

      await svc.settleAccount('emp-7');

      expect(client.lastMethod, 'POST');
      expect(client.lastPath, '/api/v1/ledger/emp-7/settle');
      expect(client.lastBody!['date'], isA<String>());
      final date = client.lastBody!['date'] as String;
      expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date), true);
    });
  });

  group('LedgerService.create', () {
    test('posts to create endpoint with body', () async {
      final client = _FakeApiClient({
        'data': {
          'id': 'led-new',
          'employee_id': 'emp-3',
          'employee_name': 'Dave',
          'date': '2026-08-10',
          'type': 'udhaar',
          'amount': 3000,
        },
      });
      final svc = LedgerService(client);

      final entry = await svc.create({
        'employee_id': 'emp-3',
        'date': '2026-08-10',
        'type': 'udhaar',
        'amount': 3000,
      });

      expect(client.lastMethod, 'POST');
      expect(client.lastPath, '/api/v1/ledger');
      expect(entry.id, 'led-new');
      expect(entry.amount, 3000);
    });
  });
}
