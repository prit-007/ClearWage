import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/core/providers/services.dart';
import 'package:clearwage/data/services/auth_service.dart';
import 'package:clearwage/data/services/notification_api_service.dart';
import 'package:clearwage/features/auth/register_page.dart';

class _NoOpApiClient extends ApiClient {
  _NoOpApiClient() : super(baseUrl: 'http://localhost');
}

class FakeAuthService extends AuthService {
  FakeAuthService()
    : super(_NoOpApiClient(), NotificationApiService(_NoOpApiClient()));
}

Widget _buildApp() {
  return ProviderScope(
    overrides: [authServiceProvider.overrideWithValue(FakeAuthService())],
    child: const MaterialApp(home: RegisterScreen()),
  );
}

void main() {
  group('RegisterScreen', () {
    testWidgets('register form renders with name and factory fields', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Send Verification Code'), findsOneWidget);
    });

    testWidgets('name field is present', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Your Full Name'), findsOneWidget);
    });

    testWidgets('factory field is present', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Factory / Business Name'), findsOneWidget);
    });

    testWidgets('phone field is present', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Mobile Number'), findsOneWidget);
    });

    testWidgets('OTP field is hidden initially', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('SECURITY CODE'), findsNothing);
    });

    testWidgets('submit button shows Send Verification Code initially', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Send Verification Code'), findsOneWidget);
    });
  });
}
