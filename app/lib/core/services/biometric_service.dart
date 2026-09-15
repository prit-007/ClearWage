import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../logger.dart';

/// Monitors app lifecycle and locks after inactivity.
final appLockProvider = StateNotifierProvider<AppLockNotifier, AppLockState>((
  ref,
) {
  return AppLockNotifier();
});

class AppLockState {
  final bool isLocked;
  final bool biometricsAvailable;
  final bool biometricsEnabled;
  final Duration inactivityTimeout;

  const AppLockState({
    this.isLocked = false,
    this.biometricsAvailable = false,
    this.biometricsEnabled = false,
    this.inactivityTimeout = const Duration(minutes: 5),
  });

  AppLockState copyWith({
    bool? isLocked,
    bool? biometricsAvailable,
    bool? biometricsEnabled,
    Duration? inactivityTimeout,
  }) {
    return AppLockState(
      isLocked: isLocked ?? this.isLocked,
      biometricsAvailable: biometricsAvailable ?? this.biometricsAvailable,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      inactivityTimeout: inactivityTimeout ?? this.inactivityTimeout,
    );
  }
}

class AppLockNotifier extends StateNotifier<AppLockState>
    with WidgetsBindingObserver {
  Timer? _inactivityTimer;
  final LocalAuthentication _localAuth = LocalAuthentication();

  AppLockNotifier() : super(const AppLockState()) {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    try {
      final available = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      state = state.copyWith(biometricsAvailable: available && canCheck);
    } catch (e) {
      AppLogger.warn('Biometric check failed: $e');
    }
    _resetTimer();
  }

  void _resetTimer() {
    _inactivityTimer?.cancel();
    if (!state.biometricsEnabled || !state.biometricsAvailable) return;
    _inactivityTimer = Timer(state.inactivityTimeout, () {
      if (mounted) {
        state = state.copyWith(isLocked: true);
        AppLogger.info('App locked due to inactivity');
      }
    });
  }

  void onUserInteraction() {
    if (state.isLocked) return;
    _resetTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resetTimer();
    }
  }

  void setBiometricsEnabled(bool enabled) {
    state = state.copyWith(biometricsEnabled: enabled);
    if (enabled) {
      _resetTimer();
    } else {
      _inactivityTimer?.cancel();
    }
  }

  Future<bool> authenticate() async {
    if (!state.biometricsAvailable) return true;
    try {
      final result = await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock ClearWage',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (result) {
        state = state.copyWith(isLocked: false);
        _resetTimer();
      }
      return result;
    } catch (e) {
      AppLogger.error('Biometric auth failed', e);
      return false;
    }
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
