import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../core/helpers.dart';
import '../../core/providers/services.dart';
import '../../core/design_tokens.dart';
import '../../core/responsive.dart';
import '../../data/models/leave_request_model.dart';

class LeaveRequestsScreen extends ConsumerStatefulWidget {
  const LeaveRequestsScreen({super.key});

  @override
  ConsumerState<LeaveRequestsScreen> createState() =>
      _LeaveRequestsScreenState();
}

class _LeaveRequestsScreenState extends ConsumerState<LeaveRequestsScreen> {
  String _tab = 'pending';

  Future<void> _approve(LeaveRequest lr) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Approve Leave?',
      message:
          '${lr.employeeName ?? 'Employee'} — ${lr.dateRange}. Approved days will be marked as paid leave.',
      confirmLabel: 'Approve',
      icon: PhosphorIconsRegular.check,
    );
    if (ok != true) return;
    try {
      await ref.read(leaveRequestServiceProvider).approve(lr.id);
      ref.invalidate(leaveRequestsProvider(_tab));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Leave approved')));
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _deny(LeaveRequest lr) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Deny Leave?',
      message: '${lr.employeeName ?? 'Employee'} — ${lr.dateRange}.',
      confirmLabel: 'Deny',
      isDestructive: true,
      icon: PhosphorIconsRegular.x,
    );
    if (ok != true) return;
    try {
      await ref.read(leaveRequestServiceProvider).deny(lr.id);
      ref.invalidate(leaveRequestsProvider(_tab));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Leave denied')));
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final async = ref.watch(leaveRequestsProvider(_tab));

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
          'Leave Requests',
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'pending', label: Text('Pending')),
                ButtonSegment(value: 'approved', label: Text('Approved')),
                ButtonSegment(value: 'denied', label: Text('Denied')),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
            const SizedBox(height: 12),
            Expanded(
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
                    return const Center(child: Text('No leave requests'));
                  }
                  return ListView.separated(
                    physics: AppScrollPhysics.physics(),
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final lr = items[index];
                      return _LeaveCard(
                        cs: cs,
                        tt: tt,
                        lr: lr,
                        onApprove: lr.isPending ? () => _approve(lr) : null,
                        onDeny: lr.isPending ? () => _deny(lr) : null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final leaveRequestsProvider = FutureProvider.autoDispose
    .family<List<LeaveRequest>, String>((ref, status) {
      return ref.watch(leaveRequestServiceProvider).list(status: status);
    });

class _LeaveCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final LeaveRequest lr;
  final VoidCallback? onApprove;
  final VoidCallback? onDeny;

  const _LeaveCard({
    required this.cs,
    required this.tt,
    required this.lr,
    required this.onApprove,
    required this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
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
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  lr.employeeName ?? lr.employeeId,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
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
          const SizedBox(height: 8),
          Text(
            '${lr.leaveType.toUpperCase()} · ${lr.dateRange}',
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (lr.reason != null && lr.reason!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              lr.reason!,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
          if (lr.isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDeny,
                    icon: const Icon(PhosphorIconsRegular.x, size: 16),
                    label: const Text('Deny'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(PhosphorIconsRegular.check, size: 16),
                    label: const Text('Approve'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
