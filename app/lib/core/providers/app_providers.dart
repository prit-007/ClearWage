import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import '../app_config.dart';
import '../token_storage.dart';
import '../../data/models/auth_model.dart';
import 'dart:async';

final sessionExpiredProvider = StateProvider<bool>((ref) => false);

final apiClientProvider = Provider<ApiClient>((ref) {
  final url = ref.watch(serverUrlProvider);
  final client = ApiClient(baseUrl: url);
  final initialToken = ref.read(tokenProvider);
  if (initialToken != null) client.setToken(initialToken);
  ref.listen(tokenProvider, (_, token) => client.setToken(token));
  client.onUnauthorized = () async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final idToken = await user.getIdToken();
        final refreshClient = ApiClient(baseUrl: url);
        final res = await refreshClient.post(
          '/api/v1/auth/firebase-login',
          body: {'id_token': idToken},
        );
        final data = res['data'] as Map<String, dynamic>? ?? {};
        final newToken = data['access_token'] as String? ?? '';
        if (newToken.isNotEmpty) {
          await TokenStorage.save(newToken);
          ref.read(tokenProvider.notifier).state = newToken;
          return;
        }
      } catch (_) {}
    }
    ref.read(tokenProvider.notifier).state = null;
    ref.read(userInfoProvider.notifier).state = null;
    ref.read(sessionExpiredProvider.notifier).state = true;
    unawaited(TokenStorage.clear());
  };
  return client;
});

final tokenProvider = StateProvider<String?>((ref) => null);

final userInfoProvider = StateProvider<AppUser?>((ref) => null);

final initialTokenProvider = FutureProvider<String?>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      final idToken = await user.getIdToken();
      final client = ApiClient(baseUrl: ref.read(serverUrlProvider));
      final res = await client.post(
        '/api/v1/auth/firebase-login',
        body: {'id_token': idToken},
      );
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final token = data['access_token'] as String? ?? '';
      if (token.isNotEmpty) {
        await TokenStorage.save(token);
        ref.read(tokenProvider.notifier).state = token;
        final info = AppUser(
          token: token,
          tenantId: data['tenant_id'] as String? ?? '',
          employeeId: data['employee_id'] as String? ?? '',
          role: data['role'] as String? ?? '',
        );
        await TokenStorage.saveUserInfo(info);
        ref.read(userInfoProvider.notifier).state = info;
        return token;
      }
    } catch (_) {
      // Firebase refresh failed; fall through to stored token
    }
  }
  final token = await TokenStorage.load();
  if (token != null) {
    ref.read(tokenProvider.notifier).state = token;
    final info = await TokenStorage.loadUserInfo();
    if (info != null) {
      ref.read(userInfoProvider.notifier).state = info;
    }
  }
  return token;
});
