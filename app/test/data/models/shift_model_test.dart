import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/data/models/shift_model.dart';

void main() {
  group('Shift', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'shift-1',
        'name': 'Morning',
        'start_time': '06:00',
        'end_time': '14:00',
        'crosses_midnight': false,
        'grace_period_minutes': 15,
        'is_default': true,
      };

      final s = Shift.fromJson(json);

      expect(s.id, 'shift-1');
      expect(s.name, 'Morning');
      expect(s.startTime, '06:00');
      expect(s.endTime, '14:00');
      expect(s.crossesMidnight, false);
      expect(s.gracePeriodMinutes, 15);
      expect(s.isDefault, true);
    });

    test('fromJson handles null/missing fields with defaults', () {
      final s = Shift.fromJson(<String, dynamic>{});

      expect(s.id, '');
      expect(s.name, '');
      expect(s.startTime, '');
      expect(s.endTime, '');
      expect(s.crossesMidnight, false);
      expect(s.gracePeriodMinutes, 0);
      expect(s.isDefault, false);
    });

    test('fromJson parses crosses_midnight as true', () {
      final s = Shift.fromJson({
        'id': 'shift-2',
        'name': 'Night',
        'start_time': '22:00',
        'end_time': '06:00',
        'crosses_midnight': true,
        'grace_period_minutes': 0,
        'is_default': false,
      });

      expect(s.crossesMidnight, true);
    });

    test('fromJson handles grace_period_minutes as string', () {
      final s = Shift.fromJson({
        'id': 'shift-3',
        'name': 'Test',
        'start_time': '08:00',
        'end_time': '16:00',
        'crosses_midnight': false,
        'grace_period_minutes': '20',
        'is_default': false,
      });

      expect(s.gracePeriodMinutes, 20);
    });

    test('toJson includes all fields except id', () {
      final s = Shift(
        id: 'shift-4',
        name: 'Evening',
        startTime: '14:00',
        endTime: '22:00',
        crossesMidnight: false,
        gracePeriodMinutes: 10,
        isDefault: true,
      );

      final json = s.toJson();

      expect(json.containsKey('id'), false);
      expect(json['name'], 'Evening');
      expect(json['start_time'], '14:00');
      expect(json['end_time'], '22:00');
      expect(json['crosses_midnight'], false);
      expect(json['grace_period_minutes'], 10);
      expect(json['is_default'], true);
    });

    test('fromJson handles grace_period_minutes as double from JSON', () {
      final s = Shift.fromJson({
        'id': 'shift-5',
        'name': 'Test',
        'start_time': '09:00',
        'end_time': '17:00',
        'crosses_midnight': false,
        'grace_period_minutes': 5.0,
        'is_default': false,
      });

      expect(s.gracePeriodMinutes, 5);
    });
  });
}
