import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/core/providers/app_providers.dart';
import 'package:clearwage/core/providers/services.dart';
import 'package:clearwage/core/services/locale_service.dart';
import 'package:clearwage/data/models/auth_model.dart';
import 'package:clearwage/data/models/employee_model.dart';
import 'package:clearwage/data/models/shift_model.dart';
import 'package:clearwage/data/services/shift_service.dart';
import 'package:clearwage/data/services/staff_service.dart';
import 'package:clearwage/features/staff/add_employee_page.dart';
import 'package:clearwage/l10n/app_localizations.dart';

class _NoOpApiClient extends ApiClient {
  _NoOpApiClient() : super(baseUrl: 'http://localhost');
}

class FakeStaffService extends StaffService {
  FakeStaffService() : super(_NoOpApiClient());

  @override
  Future<List<Employee>> list({
    int? limit,
    int? offset,
    String? query,
    String? status,
  }) async => [];
}

class FakeShiftService extends ShiftService {
  FakeShiftService() : super(_NoOpApiClient());

  @override
  Future<List<Shift>> list({int? limit, int? offset}) async => [];
}

Widget _buildApp({Locale locale = const Locale('en')}) {
  return ProviderScope(
    overrides: [
      staffServiceProvider.overrideWithValue(FakeStaffService()),
      shiftServiceProvider.overrideWithValue(FakeShiftService()),
      userInfoProvider.overrideWith(
        (ref) => AppUser(
          token: 'test',
          tenantId: 'tenant',
          employeeId: 'emp',
          role: 'owner',
        ),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AddEmployeeScreen(),
    ),
  );
}

void main() {
  group('AddEmployeeScreen', () {
    testWidgets('renders English labels', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Onboard Staff'), findsOneWidget);
      expect(find.text('CORE IDENTITY'), findsOneWidget);
      expect(find.text('Full Name *'), findsOneWidget);
      expect(find.text('Phone Number *'), findsOneWidget);
    });

    testWidgets('renders Hindi labels when locale is hi', (tester) async {
      await tester.pumpWidget(_buildApp(locale: const Locale('hi')));
      await tester.pumpAndSettle();

      expect(find.text('स्टाफ़ जोड़ें'), findsOneWidget);
      expect(find.text('मुख्य पहचान'), findsOneWidget);
      expect(find.text('पूरा नाम *'), findsOneWidget);
      expect(find.text('फ़ोन नंबर *'), findsOneWidget);
    });
  });
}
