import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/data/models/holiday_model.dart';

void main() {
  group('Holiday', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'hol-1',
        'name': 'Independence Day',
        'date': '2026-08-15',
        'is_recurring': true,
      };

      final h = Holiday.fromJson(json);

      expect(h.id, 'hol-1');
      expect(h.name, 'Independence Day');
      expect(h.date, '2026-08-15');
      expect(h.isRecurring, true);
    });

    test('fromJson handles null/missing fields with defaults', () {
      final h = Holiday.fromJson(<String, dynamic>{});

      expect(h.id, '');
      expect(h.name, '');
      expect(h.date, '');
      expect(h.isRecurring, false);
    });

    test('fromJson defaults is_recurring to false when missing', () {
      final h = Holiday.fromJson({
        'id': 'hol-2',
        'name': 'Diwali',
        'date': '2026-10-20',
      });

      expect(h.isRecurring, false);
    });

    test('toJson includes name, date, is_recurring but not id', () {
      final h = Holiday(
        id: 'hol-3',
        name: 'Christmas',
        date: '2026-12-25',
        isRecurring: true,
      );

      final json = h.toJson();

      expect(json.containsKey('id'), false);
      expect(json['name'], 'Christmas');
      expect(json['date'], '2026-12-25');
      expect(json['is_recurring'], true);
    });

    test('toJson round-trips through fromJson', () {
      final original = Holiday(
        id: 'hol-4',
        name: 'Holi',
        date: '2026-03-10',
        isRecurring: true,
      );

      final json = original.toJson();
      final restored = Holiday.fromJson({'id': 'hol-4', ...json});

      expect(restored.name, original.name);
      expect(restored.date, original.date);
      expect(restored.isRecurring, original.isRecurring);
    });
  });
}
