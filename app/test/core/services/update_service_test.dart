import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_test;
import 'package:clearwage/core/services/update_service.dart';

void main() {
  group('UpdateService', () {
    group('checkForUpdate', () {
      test('returns UpdateInfo when newer version exists', () async {
        final client = http_test.MockClient((request) async {
          return http.Response(
            jsonEncode({
              'tag_name': 'v0.9.1',
              'body': '### Fixed\n- Bug fix one\n- Bug fix two',
              'assets': [
                {
                  'name': 'app-release.apk',
                  'browser_download_url': 'https://example.com/app.apk',
                },
              ],
            }),
            200,
          );
        });

        final svc = UpdateService(client: client);
        final result = await svc.checkForUpdate('0.9.0');

        expect(result, isNotNull);
        expect(result!.latestVersion, '0.9.1');
        expect(result.downloadUrl, 'https://example.com/app.apk');
        expect(result.changelog, contains('Bug fix one'));
        expect(result.changelog, contains('Bug fix two'));
      });

      test('returns null when version is same', () async {
        final client = http_test.MockClient((request) async {
          return http.Response(
            jsonEncode({
              'tag_name': 'v0.9.0',
              'body': '- Nothing new',
              'assets': [
                {
                  'name': 'app-release.apk',
                  'browser_download_url': 'https://example.com/app.apk',
                },
              ],
            }),
            200,
          );
        });

        final svc = UpdateService(client: client);
        final result = await svc.checkForUpdate('0.9.0');

        expect(result, isNull);
      });

      test('returns null when version is older (already ahead)', () async {
        final client = http_test.MockClient((request) async {
          return http.Response(
            jsonEncode({
              'tag_name': 'v0.8.0',
              'body': '- Old stuff',
              'assets': [
                {
                  'name': 'app-release.apk',
                  'browser_download_url': 'https://example.com/app.apk',
                },
              ],
            }),
            200,
          );
        });

        final svc = UpdateService(client: client);
        final result = await svc.checkForUpdate('0.9.0');

        expect(result, isNull);
      });

      test('returns null on network error', () async {
        final client = http_test.MockClient((request) async {
          throw Exception('Network error');
        });

        final svc = UpdateService(client: client);
        final result = await svc.checkForUpdate('0.9.0');

        expect(result, isNull);
      });

      test('returns null on non-200 response', () async {
        final client = http_test.MockClient((request) async {
          return http.Response('Not Found', 404);
        });

        final svc = UpdateService(client: client);
        final result = await svc.checkForUpdate('0.9.0');

        expect(result, isNull);
      });

      test('returns null when no APK asset exists', () async {
        final client = http_test.MockClient((request) async {
          return http.Response(
            jsonEncode({
              'tag_name': 'v0.9.1',
              'body': '- Update',
              'assets': [
                {
                  'name': 'source.zip',
                  'browser_download_url': 'https://example.com/src.zip',
                },
              ],
            }),
            200,
          );
        });

        final svc = UpdateService(client: client);
        final result = await svc.checkForUpdate('0.9.0');

        expect(result, isNull);
      });

      test('handles multi-digit versions correctly', () async {
        final client = http_test.MockClient((request) async {
          return http.Response(
            jsonEncode({
              'tag_name': 'v1.0.0',
              'body': '- Major release',
              'assets': [
                {
                  'name': 'app-release.apk',
                  'browser_download_url': 'https://example.com/app.apk',
                },
              ],
            }),
            200,
          );
        });

        final svc = UpdateService(client: client);
        final result = await svc.checkForUpdate('0.99.99');

        expect(result, isNotNull);
        expect(result!.latestVersion, '1.0.0');
      });
    });

    group('changelog parsing', () {
      test('parses bullet-point changelog', () async {
        final client = http_test.MockClient((request) async {
          return http.Response(
            jsonEncode({
              'tag_name': 'v0.9.1',
              'body': '- Feature A\n- Feature B\n- Bug fix C',
              'assets': [
                {
                  'name': 'app-release.apk',
                  'browser_download_url': 'https://example.com/app.apk',
                },
              ],
            }),
            200,
          );
        });

        final svc = UpdateService(client: client);
        final result = await svc.checkForUpdate('0.9.0');

        expect(result, isNotNull);
        expect(result!.changelog, ['Feature A', 'Feature B', 'Bug fix C']);
      });

      test('parses section headers from markdown', () async {
        final client = http_test.MockClient((request) async {
          return http.Response(
            jsonEncode({
              'tag_name': 'v0.9.1',
              'body': '### New Features\n- Added X\n### Bug Fixes\n- Fixed Y',
              'assets': [
                {
                  'name': 'app-release.apk',
                  'browser_download_url': 'https://example.com/app.apk',
                },
              ],
            }),
            200,
          );
        });

        final svc = UpdateService(client: client);
        final result = await svc.checkForUpdate('0.9.0');

        expect(result, isNotNull);
        expect(result!.changelog, contains('New Features'));
        expect(result.changelog, contains('Added X'));
        expect(result.changelog, contains('Bug Fixes'));
        expect(result.changelog, contains('Fixed Y'));
      });

      test('returns default message for empty changelog', () async {
        final client = http_test.MockClient((request) async {
          return http.Response(
            jsonEncode({
              'tag_name': 'v0.9.1',
              'body': '',
              'assets': [
                {
                  'name': 'app-release.apk',
                  'browser_download_url': 'https://example.com/app.apk',
                },
              ],
            }),
            200,
          );
        });

        final svc = UpdateService(client: client);
        final result = await svc.checkForUpdate('0.9.0');

        expect(result, isNotNull);
        expect(result!.changelog, ['Bug fixes and improvements']);
      });
    });
  });
}
