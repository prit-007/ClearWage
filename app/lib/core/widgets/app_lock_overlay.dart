import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/biometric_service.dart';
import 'app_lock_screen.dart';

/// Wraps child and shows lock screen overlay when app is locked.
class AppLockOverlay extends ConsumerWidget {
  final Widget child;
  const AppLockOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockState = ref.watch(appLockProvider);

    return GestureDetector(
      onTap: () => ref.read(appLockProvider.notifier).onUserInteraction(),
      onPanDown: (_) => ref.read(appLockProvider.notifier).onUserInteraction(),
      child: Stack(
        children: [
          child,
          if (lockState.isLocked) const Positioned.fill(child: AppLockScreen()),
        ],
      ),
    );
  }
}
