import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/design_tokens.dart';
import '../../core/helpers.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../data/models/notification_model.dart';
import 'providers/notification_providers.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final notificationsAsync = ref.watch(notificationListProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        title: Text(
          'Notifications',
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await ref.read(notificationApiServiceProvider).markAllRead();
                ref.invalidate(unreadCountProvider);
                ref.invalidate(notificationListProvider);
              } catch (e) {
                if (context.mounted) showError(context, e);
              }
            },
            child: Text(
              'Mark all read',
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const CustomScrollView(
          slivers: [ShimmerLoading(itemCount: 5, height: 80)],
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIconsRegular.warningCircle,
                  size: 48,
                  color: cs.error,
                ),
                const SizedBox(height: 16),
                Text('Something went wrong', style: tt.titleMedium),
                const SizedBox(height: 8),
                Text('$e', style: tt.bodySmall, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(PhosphorIconsBold.arrowClockwise),
                  label: const Text('Retry'),
                  onPressed: () => ref.invalidate(notificationListProvider),
                ),
              ],
            ),
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: EmptyState(
                icon: PhosphorIconsRegular.bell,
                title: "You're all caught up!",
                subtitle: 'No notifications yet.',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationListProvider);
              ref.invalidate(unreadCountProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return _NotificationTile(
                  notification: notifications[index],
                  onTap: () => _handleTap(context, notifications[index]),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _handleTap(BuildContext context, AppNotification notification) async {
    // Mark as read
    if (!notification.isRead) {
      try {
        await ref
            .read(notificationApiServiceProvider)
            .markRead(notification.id);
        ref.invalidate(unreadCountProvider);
        ref.invalidate(notificationListProvider);
      } catch (_) {}
    }

    // Navigate to entity
    if (!context.mounted) return;
    switch (notification.entityType) {
      case 'attendance':
        await context.push('/my-attendance');
        break;
      case 'advance_request':
        await context.push('/my-advance-requests');
        break;
      case 'ledger':
        await context.push('/my-ledger');
        break;
      case 'dispute':
        await context.push('/disputes');
        break;
      case 'payroll':
        await context.push('/my-profile');
        break;
      default:
        break;
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final (icon, color) = _iconForType(notification.type);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.transparent
              : cs.primary.withValues(alpha: 0.04),
          border: Border(
            bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: tt.titleSmall?.copyWith(
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.timeAgo,
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _iconForType(String type) {
    switch (type) {
      case 'attendance':
        return (PhosphorIconsRegular.calendarCheck, AppColors.success);
      case 'advance':
        return (PhosphorIconsRegular.coins, AppColors.warning);
      case 'ledger':
        return (PhosphorIconsRegular.receipt, AppColors.info);
      case 'dispute':
        return (PhosphorIconsRegular.flag, AppColors.danger);
      case 'payroll':
        return (PhosphorIconsRegular.fileText, AppColors.purple);
      default:
        return (PhosphorIconsRegular.bell, AppColors.info);
    }
  }
}
