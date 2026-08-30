import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_tokens.dart';
import '../../features/notifications/providers/notification_providers.dart';

class NotificationBadge extends ConsumerWidget {
  final Widget child;
  const NotificationBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(unreadCountProvider);

    return countAsync.when(
      loading: () => child,
      error: (e, _) {
        debugPrint('Unread count error: $e');
        return child;
      },
      data: (count) {
        if (count <= 0) return child;
        return Badge(
          isLabelVisible: true,
          label: Text(
            count > 99 ? '99+' : '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          backgroundColor: AppColors.danger,
          child: child,
        );
      },
    );
  }
}
