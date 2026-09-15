import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logger.dart';

/// Monitors network connectivity and exposes the current state.
final connectivityProvider = StreamNotifierProvider<ConnectivityNotifier, bool>(
  ConnectivityNotifier.new,
);

class ConnectivityNotifier extends StreamNotifier<bool> {
  final _connectivity = Connectivity();

  @override
  Stream<bool> build() async* {
    // Emit initial state
    final result = await _connectivity.checkConnectivity();
    yield _isConnected(result);

    // Listen for changes
    yield* _connectivity.onConnectivityChanged.map((result) {
      final connected = _isConnected(result);
      AppLogger.info(connected ? 'Network connected' : 'Network disconnected');
      return connected;
    });
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }
}
