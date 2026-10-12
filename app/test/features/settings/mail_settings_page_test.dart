import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/core/providers/services.dart';
import 'package:clearwage/data/services/settings_service.dart';
import 'package:clearwage/features/settings/mail_settings_page.dart';

class _NoOpApiClient extends ApiClient {
  _NoOpApiClient() : super(baseUrl: 'http://localhost');
}

class FakeSettingsService extends SettingsService {
  Map<String, dynamic> _data = {};
  Completer<Map<String, dynamic>>? _pending;

  FakeSettingsService() : super(_NoOpApiClient());

  void setData(Map<String, dynamic> data) => _data = data;

  void simulateSlow() {
    _pending = Completer<Map<String, dynamic>>();
  }

  void completeSlow() {
    _pending?.complete(_data);
    _pending = null;
  }

  @override
  Future<Map<String, dynamic>> getMailSettings() async {
    if (_pending != null) return _pending!.future;
    return _data;
  }
}

void main() {
  testWidgets('loads and renders mail settings', (tester) async {
    final svc = FakeSettingsService()
      ..setData({
        'account_email': 'owner@factory.test',
        'brevo_api_key': 'xkeysample',
        'mail_sender_email': 'noreply@factory.test',
        'mail_sender_name': 'Acme',
        'mail_quota_per_day': 300,
        'mail_sent_today': 12,
      });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsServiceProvider.overrideWithValue(svc)],
        child: const MaterialApp(home: MailSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Email Settings'), findsOneWidget);
    expect(find.text('Your Email (receives account emails)'), findsOneWidget);
    expect(find.text('owner@factory.test'), findsOneWidget);
    expect(find.text('Sent today: 12'), findsOneWidget);
    expect(find.text('Save Settings'), findsOneWidget);
  });

  testWidgets('shows loading indicator initially', (tester) async {
    final svc = FakeSettingsService()..simulateSlow();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsServiceProvider.overrideWithValue(svc)],
        child: const MaterialApp(home: MailSettingsPage()),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    svc.completeSlow();
    await tester.pumpAndSettle();
  });
}
