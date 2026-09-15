import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'logger.dart';
import 'token_storage.dart';

String _defaultBaseUrl() => 'https://work-force-nckb.onrender.com';

/// Persists the server URL across restarts.
final serverUrlProvider = StateNotifierProvider<ServerUrlNotifier, String>((
  ref,
) {
  return ServerUrlNotifier();
});

class ServerUrlNotifier extends StateNotifier<String> {
  ServerUrlNotifier() : super(_defaultBaseUrl()) {
    _load();
  }

  static const _key = 'server_url';

  Future<void> _load() async {
    try {
      final saved = await TokenStorage.read(_key);
      if (saved != null && saved.isNotEmpty) {
        state = saved;
      }
    } catch (e) {
      AppLogger.warn('Failed to load saved server URL: $e');
    }
  }

  Future<void> update(String url) async {
    state = url;
    try {
      await TokenStorage.write(_key, url);
    } catch (e) {
      AppLogger.warn('Failed to save server URL: $e');
    }
  }
}
