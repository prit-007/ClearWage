import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/core/api_exceptions.dart';
import 'package:vivek_app/core/helpers.dart';

void main() {
  group('asMapList', () {
    test('returns empty list for non-list input', () {
      expect(asMapList(null), isEmpty);
      expect(asMapList('string'), isEmpty);
      expect(asMapList(42), isEmpty);
      expect(asMapList({'key': 'val'}), isEmpty);
    });

    test('converts list of maps to List<Map<String, dynamic>>', () {
      final input = [
        {'a': 1, 'b': 2},
        {'c': 3},
      ];
      final result = asMapList(input);
      expect(result, hasLength(2));
      expect(result[0]['a'], 1);
      expect(result[1]['c'], 3);
    });

    test('skips non-map elements in list', () {
      final input = [
        1,
        'str',
        {'key': 'val'},
        null,
      ];
      final result = asMapList(input);
      expect(result, hasLength(1));
      expect(result[0]['key'], 'val');
    });

    test('returns empty list for empty list', () {
      expect(asMapList([]), isEmpty);
    });
  });

  group('safeToInt', () {
    test('returns 0 for null', () {
      expect(safeToInt(null), 0);
    });

    test('returns value for int', () {
      expect(safeToInt(42), 42);
    });

    test('converts double to int', () {
      expect(safeToInt(3.7), 3);
    });

    test('parses numeric string', () {
      expect(safeToInt('15'), 15);
    });

    test('returns fallback for non-parseable string', () {
      expect(safeToInt('abc'), 0);
      expect(safeToInt('abc', 5), 5);
    });

    test('returns fallback for unsupported types', () {
      expect(safeToInt(true), 0);
      expect(safeToInt(true, -1), -1);
    });

    test('returns custom fallback', () {
      expect(safeToInt(null, -1), -1);
      expect(safeToInt('bad', 100), 100);
    });
  });

  group('safeToDouble', () {
    test('returns 0.0 for null', () {
      expect(safeToDouble(null), 0.0);
    });

    test('returns value for double', () {
      expect(safeToDouble(3.14), 3.14);
    });

    test('converts int to double', () {
      expect(safeToDouble(5), 5.0);
      expect(safeToDouble(5), isA<double>());
    });

    test('parses numeric string', () {
      expect(safeToDouble('2.5'), 2.5);
    });

    test('returns fallback for non-parseable string', () {
      expect(safeToDouble('abc'), 0.0);
      expect(safeToDouble('abc', 1.5), 1.5);
    });

    test('returns fallback for unsupported types', () {
      expect(safeToDouble(true), 0.0);
      expect(safeToDouble(true, -1.0), -1.0);
    });
  });

  group('formatDate', () {
    test('formats DateTime without year for current year', () {
      final now = DateTime.now();
      final dt = DateTime(now.year, 3, 1);
      final result = formatDate(dt);
      expect(result, contains('March'));
      expect(result, contains('1st'));
      expect(result.contains('${now.year}'), false);
    });

    test('formats DateTime with year for different year', () {
      final dt = DateTime(2024, 12, 25);
      final result = formatDate(dt);
      expect(result, contains('December'));
      expect(result, contains('25th'));
      expect(result, contains('2024'));
    });

    test('formats date string', () {
      final result = formatDate('2026-01-15');
      expect(result, contains('January'));
      expect(result, contains('15th'));
    });

    test('returns raw string for invalid input', () {
      expect(formatDate('not-a-date'), 'not-a-date');
      expect(formatDate(42), '42');
    });

    test('uses correct ordinals', () {
      expect(formatDate(DateTime(2026, 1, 1)), contains('1st'));
      expect(formatDate(DateTime(2026, 1, 2)), contains('2nd'));
      expect(formatDate(DateTime(2026, 1, 3)), contains('3rd'));
      expect(formatDate(DateTime(2026, 1, 4)), contains('4th'));
      expect(formatDate(DateTime(2026, 1, 11)), contains('11th'));
      expect(formatDate(DateTime(2026, 1, 12)), contains('12th'));
      expect(formatDate(DateTime(2026, 1, 13)), contains('13th'));
      expect(formatDate(DateTime(2026, 1, 21)), contains('21st'));
      expect(formatDate(DateTime(2026, 1, 22)), contains('22nd'));
      expect(formatDate(DateTime(2026, 1, 23)), contains('23rd'));
    });
  });

  group('formatTime', () {
    test('formats midnight (00:xx)', () {
      expect(formatTime('00:30'), '12:30 AM');
    });

    test('formats morning hours', () {
      expect(formatTime('09:15'), '9:15 AM');
    });

    test('formats noon', () {
      expect(formatTime('12:00'), '12:00 PM');
    });

    test('formats afternoon hours', () {
      expect(formatTime('14:30'), '2:30 PM');
    });

    test('formats evening hours', () {
      expect(formatTime('23:59'), '11:59 PM');
    });

    test('returns empty string for null', () {
      expect(formatTime(null), '');
    });

    test('returns empty string for empty string', () {
      expect(formatTime(''), '');
    });

    test('returns original string when no colon', () {
      expect(formatTime('1234'), '1234');
    });

    test('includes seconds when present and non-zero', () {
      expect(formatTime('09:15:30'), '9:15 AM:30');
    });

    test('omits seconds when 00', () {
      expect(formatTime('09:15:00'), '9:15 AM');
    });
  });

  group('getInitials', () {
    test('returns first letter of single name', () {
      expect(getInitials('John'), 'J');
    });

    test('returns first letters of two names', () {
      expect(getInitials('John Doe'), 'JD');
    });

    test('returns only first two initials for three+ names', () {
      expect(getInitials('John Michael Doe'), 'JM');
    });

    test('handles extra whitespace', () {
      expect(getInitials('  John   Doe  '), 'JD');
    });

    test('returns ? for empty string', () {
      expect(getInitials(''), '?');
    });

    test('uppercases initials', () {
      expect(getInitials('john doe'), 'JD');
    });
  });

  group('resolveMediaUrl', () {
    test('returns full URL as-is', () {
      final url = 'https://example.com/photo.jpg';
      expect(resolveMediaUrl(url, 'https://api.test'), url);
    });

    test('returns empty string for empty url', () {
      expect(resolveMediaUrl('', 'https://api.test'), '');
    });

    test('prepends baseUrl for relative path without leading slash', () {
      expect(
        resolveMediaUrl('uploads/photo.jpg', 'https://api.test'),
        'https://api.test/uploads/photo.jpg',
      );
    });

    test('prepends baseUrl for relative path with leading slash', () {
      expect(
        resolveMediaUrl('/uploads/photo.jpg', 'https://api.test'),
        'https://api.test/uploads/photo.jpg',
      );
    });

    test('strips trailing slash from baseUrl', () {
      expect(
        resolveMediaUrl('/uploads/photo.jpg', 'https://api.test/'),
        'https://api.test/uploads/photo.jpg',
      );
    });

    test('handles protocol-relative URLs', () {
      expect(
        resolveMediaUrl('//cdn.example.com/img.jpg', 'https://api.test'),
        'https://cdn.example.com/img.jpg',
      );
    });
  });

  group('friendlyError', () {
    test('returns default message for null', () {
      expect(friendlyError(null), 'Something went wrong');
    });

    test('returns ApiException message', () {
      final e = ApiException('Bad request', statusCode: 400);
      expect(friendlyError(e), 'Bad request');
    });

    test(
      'returns Something went wrong for ApiException with empty message',
      () {
        expect(friendlyError(ApiException('')), 'Something went wrong');
      },
    );

    test('returns error string for generic exceptions', () {
      final result = friendlyError(Exception('test error'));
      expect(result, contains('test error'));
    });

    test('truncates long messages to 200 chars', () {
      final longMsg = 'x' * 300;
      final result = friendlyError(Exception(longMsg));
      expect(result.length, lessThan(300));
      expect(result, endsWith('...'));
    });
  });
}
