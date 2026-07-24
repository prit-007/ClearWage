import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/main.dart';

void main() {
  testWidgets('App renders factory workforce', (WidgetTester tester) async {
    await tester.pumpWidget(const FactoryWorkforceApp());
    expect(find.text('Factory Workforce'), findsWidgets);
  });
}
