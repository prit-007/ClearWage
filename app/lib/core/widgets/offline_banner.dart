import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/connectivity_service.dart';

/// Shows a persistent banner at the bottom of the screen when offline.
class OfflineBanner extends ConsumerWidget {
  final Widget child;
  const OfflineBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(connectivityProvider).valueOrNull ?? true;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(child: child),
        if (!isConnected)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.orange.shade700,
            child: const SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'You are offline. Some features may be limited.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
