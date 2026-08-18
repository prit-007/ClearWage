import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/data/models/api_response.dart';

void main() {
  group('ApiResponse', () {
    test('isSuccess returns true for success status', () {
      final res = ApiResponse<String>(status: 'success', data: 'ok');
      expect(res.isSuccess, true);
    });

    test('isSuccess returns false for error status', () {
      final res = ApiResponse<String>(status: 'error');
      expect(res.isSuccess, false);
    });

    test('isSuccess returns false for fail status', () {
      final res = ApiResponse<String>(status: 'fail');
      expect(res.isSuccess, false);
    });

    test('fromJson parses status, data, and message', () {
      final json = {
        'status': 'success',
        'data': 'hello',
        'message': 'All good',
      };

      final res = ApiResponse<String>.fromJson(json, (data) => data as String);

      expect(res.status, 'success');
      expect(res.data, 'hello');
      expect(res.message, 'All good');
    });

    test('fromJson defaults status to error when missing', () {
      final res = ApiResponse<dynamic>.fromJson(<String, dynamic>{}, null);

      expect(res.status, 'error');
      expect(res.data, isNull);
      expect(res.message, isNull);
    });

    test('fromJson applies fromData transformer to data', () {
      final json = {
        'status': 'success',
        'data': {'count': 5},
      };

      final res = ApiResponse<Map<String, dynamic>>.fromJson(
        json,
        (data) => data as Map<String, dynamic>,
      );

      expect(res.data, isA<Map<String, dynamic>>());
      expect(res.data!['count'], 5);
    });

    test('fromJson returns null data when fromData is null', () {
      final json = {'status': 'success', 'data': 'something'};

      final res = ApiResponse<dynamic>.fromJson(json, null);

      expect(res.data, isNull);
    });

    test('fromJson returns null data when data field is null', () {
      final json = {'status': 'success', 'data': null};

      final res = ApiResponse<String>.fromJson(json, (data) => data as String);

      expect(res.data, isNull);
    });

    test('constructor stores all fields', () {
      final res = ApiResponse<int>(status: 'success', data: 42, message: 'OK');

      expect(res.status, 'success');
      expect(res.data, 42);
      expect(res.message, 'OK');
    });
  });
}
