import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/providers/services.dart';
import 'package:clearwage/core/services/locale_service.dart';
import 'package:clearwage/core/services/whatsapp_service.dart';
import 'package:clearwage/data/models/employee_model.dart';
import 'package:clearwage/features/dashboard/broadcast_sheet.dart';
import 'package:clearwage/features/staff/providers/staff_providers.dart';
import 'package:clearwage/l10n/app_localizations.dart';

class FakeWhatsappService extends WhatsappService {
  final List<({String phone, String text})> calls = [];

  @override
  Future<bool> launch({required String phone, required String text}) async {
    calls.add((phone: phone, text: text));
    return true;
  }
}

List<Employee> _employees() => [
  Employee(
    id: 'e1',
    name: 'Ramesh Patel',
    phone: '9876543210',
    wageType: 'daily',
    wageAmount: 500,
    role: 'employee',
    isActive: true,
  ),
  Employee(
    id: 'e2',
    name: 'Suresh Shah',
    phone: '',
    wageType: 'daily',
    wageAmount: 400,
    role: 'employee',
    isActive: true,
  ),
];

Widget _buildSheet(FakeWhatsappService svc) {
  return ProviderScope(
    overrides: [
      employeeListProvider.overrideWith((ref) async => _employees()),
      whatsappServiceProvider.overrideWithValue(svc),
    ],
    child: const MaterialApp(
      locale: Locale('en'),
      supportedLocales: supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: BroadcastSheet()),
    ),
  );
}

void main() {
  testWidgets('renders active staff and disables send when none selected', (
    tester,
  ) async {
    final svc = FakeWhatsappService();
    await tester.pumpWidget(_buildSheet(svc));
    await tester.pumpAndSettle();

    expect(find.text('Broadcast Message'), findsOneWidget);
    expect(find.text('Ramesh Patel'), findsOneWidget);
    expect(find.text('Suresh Shah'), findsOneWidget);
    expect(find.text('Select staff to send'), findsOneWidget);
  });

  testWidgets('launches WhatsApp for selected staff with a phone', (
    tester,
  ) async {
    final svc = FakeWhatsappService();
    await tester.pumpWidget(_buildSheet(svc));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ramesh Patel'));
    await tester.pumpAndSettle();

    expect(find.text('Send to 1'), findsOneWidget);

    await tester.tap(find.text('Send to 1'));
    await tester.pumpAndSettle();

    expect(svc.calls, hasLength(1));
    expect(svc.calls.first.phone, '9876543210');
  });
}
