import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/core/api_client.dart';
import 'package:vivek_app/data/services/settings_service.dart';

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
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    lastMethod = 'GET';
    lastPath = path;
    if (_error != null) throw _error;
    return _response;
  }

  @override
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    lastMethod = 'PUT';
    lastPath = path;
    lastBody = body;
    if (_error != null) throw _error;
    return _response;
  }
}

void main() {
  group('SettingsService.getPayrollSettings', () {
    test('hits settings/payroll endpoint', () async {
      final client = _FakeApiClient({
        'data': {
          'ot_trigger': 'after_shift_end',
          'ot_threshold_hours': 8,
          'ot_multiplier_default': 2.0,
          'ot_rounding': 30,
          'wage_basis': 'calendar',
          'week_off_paid': true,
          'weekly_offs': '1',
        },
      });
      final svc = SettingsService(client);

      final settings = await svc.getPayrollSettings();

      expect(client.lastMethod, 'GET');
      expect(client.lastPath, '/api/v1/settings/payroll');
      expect(settings.otTrigger, 'after_shift_end');
      expect(settings.otThresholdHours, 8);
      expect(settings.otMultiplierDefault, 2.0);
      expect(settings.wageBasis, 'calendar');
      expect(settings.weekOffPaid, true);
    });

    test('returns defaults when data is empty', () async {
      final client = _FakeApiClient({});
      final svc = SettingsService(client);

      final settings = await svc.getPayrollSettings();

      expect(settings.otThresholdHours, 8);
      expect(settings.otMultiplierDefault, 2);
      expect(settings.weekOffPaid, true);
    });

    test('propagates errors', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = SettingsService(client);

      expect(() => svc.getPayrollSettings(), throwsException);
    });
  });

  group('SettingsService.upsertPayrollSettings', () {
    test('PUTs to settings/payroll with body', () async {
      final client = _FakeApiClient({
        'data': {
          'ot_trigger': 'after_daily_hours',
          'ot_threshold_hours': 10,
          'ot_multiplier_default': 1.5,
          'ot_rounding': 15,
          'wage_basis': 'fixed_26',
          'week_off_paid': false,
          'weekly_offs': '1,7',
        },
      });
      final svc = SettingsService(client);

      final settings = await svc.upsertPayrollSettings({
        'ot_trigger': 'after_daily_hours',
        'ot_threshold_hours': 10,
      });

      expect(client.lastMethod, 'PUT');
      expect(client.lastPath, '/api/v1/settings/payroll');
      expect(settings.otTrigger, 'after_daily_hours');
      expect(settings.otThresholdHours, 10);
    });

    test('propagates errors', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = SettingsService(client);

      expect(
        () => svc.upsertPayrollSettings({'ot_trigger': 'test'}),
        throwsException,
      );
    });
  });
}
