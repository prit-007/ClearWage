import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/core/api_client.dart';
import 'package:vivek_app/data/services/onboarding_service.dart';

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
}

void main() {
  group('OnboardingService.setup', () {
    test('POSTs to onboarding/setup with body', () async {
      final client = _FakeApiClient({
        'data': {'message': 'setup complete'},
      });
      final svc = OnboardingService(client);

      final body = {
        'factory_name': 'Test Factory',
        'factory_phone': '1234567890',
        'shifts': [
          {'name': 'Morning', 'start_time': '06:00', 'end_time': '14:00'},
        ],
        'ot_settings': {'ot_trigger': 'after_shift_end'},
        'leave_policy': {'paid_leave_days_per_year': 12},
        'holidays': [
          {'name': 'Holiday', 'date': '2026-01-01'},
        ],
      };

      final result = await svc.setup(body);

      expect(client.lastMethod, 'POST');
      expect(client.lastPath, '/api/v1/onboarding/setup');
      expect(client.lastBody!['factory_name'], 'Test Factory');
      expect(result['message'], 'setup complete');
    });

    test('returns empty map when data is missing', () async {
      final client = _FakeApiClient({});
      final svc = OnboardingService(client);

      final result = await svc.setup({'factory_name': 'F'});

      expect(result, isEmpty);
    });

    test('propagates errors', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = OnboardingService(client);

      expect(() => svc.setup({'factory_name': 'F'}), throwsException);
    });
  });
}
