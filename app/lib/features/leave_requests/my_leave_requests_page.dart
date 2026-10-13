import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../core/helpers.dart';
import '../../core/design_tokens.dart';
import '../../core/providers/services.dart';
import '../../core/responsive.dart';
import '../../data/models/leave_request_model.dart';

final myLeaveRequestsProvider = FutureProvider.autoDispose<List<LeaveRequest>>(
  (ref) => ref.watch(leaveRequestServiceProvider).mine(),
);

class MyLeaveRequestsPage extends ConsumerWidget {
  const MyLeaveRequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final async = ref.watch(myLeaveRequestsProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft, color: cs.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'My Leave Requests',
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                friendlyError(e),
                style: tt.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const Center(child: Text('No leave requests yet'));
            }
            return ListView.separated(
              physics: AppScrollPhysics.physics(),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final lr = items[index];
                final Color statusColor;
                if (lr.isApproved) {
                  statusColor = AppColors.success;
                } else if (lr.isDenied) {
                  statusColor = AppColors.danger;
                } else {
                  statusColor = AppColors.warning;
                }
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          PhosphorIconsRegular.calendarCheck,
                          size: 18,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lr.dateRange,
                              style: tt.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${lr.leaveType.toUpperCase()}'
                              '${lr.reason != null && lr.reason!.isNotEmpty ? ' · ${lr.reason}' : ''}',
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            if (lr.isDenied && lr.denyReason != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                'Denied: ${lr.denyReason}',
                                style: tt.bodySmall?.copyWith(
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          lr.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
