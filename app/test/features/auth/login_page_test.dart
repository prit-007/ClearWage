import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/core/api_client.dart';
import 'package:vivek_app/core/providers/services.dart';
import 'package:vivek_app/data/services/auth_service.dart';
import 'package:vivek_app/features/auth/login_page.dart';

class _NoOpApiClient extends ApiClient {
  _NoOpApiClient() : super(baseUrl: 'http://localhost');
}

class FakeAuthService extends AuthService {
  FakeAuthService() : super(_NoOpApiClient());
}

Widget _buildApp() {
  return ProviderScope(
    overrides: [authServiceProvider.overrideWithValue(FakeAuthService())],
    child: const MaterialApp(home: LoginScreen()),
  );
}

void main() {
  group('LoginScreen', () {
    testWidgets('login form renders with phone field', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Workforce Portal'), findsOneWidget);
      expect(find.text('Continue with Phone'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('phone field is present', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('OTP field is hidden initially', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('SECURITY CODE'), findsNothing);
    });

    testWidgets('create account link is present', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining("Don't have an account"), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('submit button shows Continue with Phone initially', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Continue with Phone'), findsOneWidget);
    });
  });
}
