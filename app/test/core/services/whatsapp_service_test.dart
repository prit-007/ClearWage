import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/services/whatsapp_service.dart';

void main() {
  final svc = WhatsappService();

  group('buildUri', () {
    test('strips non-digits from phone', () {
      final uri = svc.buildUri(phone: '+91 98765 43210', text: 'hi');
      expect(uri.toString(), startsWith('https://wa.me/919876543210'));
    });

    test('URL-encodes the text', () {
      final uri = svc.buildUri(phone: '9876543210', text: 'નમસ્તે Ramesh!');
      expect(uri.queryParameters['text'], 'નમસ્તે Ramesh!');
      expect(uri.toString(), contains('text='));
      expect(uri.toString(), contains('%'));
    });
  });

  group('messages', () {
    test('greeting includes name', () {
      expect(svc.greeting(name: 'Ramesh'), contains('Ramesh'));
    });

    test('salary message includes amount and balance', () {
      final msg = svc.salaryMessage(
        name: 'Ramesh',
        salary: 12000,
        balance: 1500,
      );
      expect(msg, contains('Ramesh'));
      expect(msg, contains('₹12,000'));
      expect(msg, contains('₹1,500'));
    });
  });
}
