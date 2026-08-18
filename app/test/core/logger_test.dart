import 'package:flutter_test/flutter_test.dart';
import 'package:talker/talker.dart';
import 'package:vivek_app/core/logger.dart';

void main() {
  group('AppLogger', () {
    late Talker talker;

    setUp(() {
      talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
      AppLogger.init(talker: talker);
    });

    test('info writes to history', () {
      AppLogger.info('Hello info');
      expect(talker.history, hasLength(1));
      expect(talker.history.first.message, 'Hello info');
    });

    test('warn writes to history', () {
      AppLogger.warn('Careful now');
      expect(talker.history, hasLength(1));
      expect(talker.history.first.message, 'Careful now');
    });

    test('error writes message and exception to history', () {
      AppLogger.error('Boom', StateError('bad'), StackTrace.current);
      expect(talker.history, hasLength(1));
      final log = talker.history.first;
      expect(log.message, 'Boom');
      expect(log.exception, isA<StateError>());
    });

    test('error without exception still logs', () {
      AppLogger.error('Just a message');
      expect(talker.history, hasLength(1));
      expect(talker.history.first.message, 'Just a message');
    });

    test('request writes an http log with status and duration', () {
      AppLogger.request(
        'GET',
        '/api/v1/ledger',
        status: 200,
        duration: const Duration(milliseconds: 12),
      );
      expect(talker.history, hasLength(1));
      final log = talker.history.first;
      expect(log.key, TalkerKey.httpRequest);
      expect(log.message, contains('GET /api/v1/ledger'));
      expect(log.message, contains('status=200'));
      expect(log.message, contains('duration=12ms'));
    });
  });
}
