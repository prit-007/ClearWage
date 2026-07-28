import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../core/token_storage.dart';
import '../../models/attendance_model.dart';
import '../../providers/providers.dart';
import '../../core/helpers.dart';

final myProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.watch(profileServiceProvider).getProfile();
});

final myAttendanceProvider = FutureProvider.autoDispose<List<Attendance>>((ref) {
  final now = DateTime.now();
  final start = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
  final end = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  return ref.watch(profileServiceProvider).getAttendance(start: start, end: end);
});

final myLedgerProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  final now = DateTime.now();
  final start = '${now.year}-01-01';
  final end = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  return ref.watch(profileServiceProvider).getLedger(start: start, end: end);
});

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});
  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) HapticFeedback.selectionClick();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _downloadPayslip() async {
    HapticFeedback.heavyImpact();
    setState(() => _downloading = true);
    try {
      final now = DateTime.now();
      final start = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
      final end = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final client = ref.read(apiClientProvider);
      final bytes = await client.getRaw('/api/v1/me/payslip', query: {'start_date': start, 'end_date': end});
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/payslip_$start.pdf');
      await file.writeAsBytes(bytes);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payslip downloaded successfully')));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('My Profile', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: ref.watch(myProfileProvider).when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIconsFill.warningCircle, size: 48, color: cs.error),
                const SizedBox(height: 16),
                Text('Something went wrong', style: tt.titleMedium),
                const SizedBox(height: 8),
                Text('$e', style: tt.bodySmall, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(PhosphorIconsFill.arrowClockwise),
                  label: const Text('Retry'),
                  onPressed: () => ref.invalidate(myProfileProvider),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          final name = data['name'] as String? ?? 'User';
          final role = data['role'] as String? ?? '';
          final initials = getInitials(name);

          return NestedScrollView(
            physics: const BouncingScrollPhysics(),
            headerSliverBuilder: (_, _) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: cs.primary.withValues(alpha: 0.2), width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: cs.primaryContainer,
                            child: Text(initials, style: tt.headlineMedium?.copyWith(color: cs.onPrimaryContainer, fontWeight: FontWeight.w800)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(name, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(8)),
                          child: Text(role.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: cs.onPrimaryContainer)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  TabBar(
                    controller: _tabCtrl,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicator: BoxDecoration(borderRadius: BorderRadius.circular(24), color: cs.primaryContainer),
                    labelColor: cs.onPrimaryContainer,
                    unselectedLabelColor: cs.onSurfaceVariant,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    dividerColor: Colors.transparent,
                    splashBorderRadius: BorderRadius.circular(24),
                    isScrollable: true,
                    tabs: const [
                      Tab(text: 'Profile'),
                      Tab(text: 'Attendance'),
                      Tab(text: 'Ledger'),
                      Tab(text: 'Payslip'),
                    ],
                  ),
                  cs.surfaceContainerLowest,
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabCtrl,
              physics: const BouncingScrollPhysics(),
              children: [
                _ProfileTab(cs: cs, tt: tt, data: data),
                _MyAttendanceTab(cs: cs, tt: tt),
                _MyLedgerTab(cs: cs, tt: tt),
                _PayslipTab(cs: cs, tt: tt, onDownload: _downloadPayslip, isDownloading: _downloading),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color bgColor;
  _TabBarDelegate(this.tabBar, this.bgColor);

  @override
  Widget build(BuildContext context, _, _) => Container(color: bgColor, padding: const EdgeInsets.only(bottom: 8), child: tabBar);
  @override
  double get maxExtent => 56;
  @override
  double get minExtent => 56;
  @override
  bool shouldRebuild(_) => false;
}

class _ProfileTab extends ConsumerWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final Map<String, dynamic> data;
  const _ProfileTab({required this.cs, required this.tt, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phone = data['phone'] as String? ?? '';
    final email = data['email'] as String? ?? '';
    final role = data['role'] as String? ?? '';
    final factoryName = data['factory_name'] as String? ?? data['tenant_name'] as String? ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3))),
          child: Column(
            children: [
              _InfoRow(cs: cs, label: 'Phone', value: phone),
              const Divider(height: 24),
              _InfoRow(cs: cs, label: 'Email', value: email.isNotEmpty ? email : 'Not set'),
              const Divider(height: 24),
              _InfoRow(cs: cs, label: 'Role', value: role),
              const Divider(height: 24),
              _InfoRow(cs: cs, label: 'Factory', value: factoryName.isNotEmpty ? factoryName : 'Not set'),
            ],
          ),
        ),
        const SizedBox(height: 24),
          SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Sign Out', style: TextStyle(color: cs.error))),
                  ],
                ),
              );
              if (confirmed != true) return;
              await ref.read(authServiceProvider).logout();
              ref.read(tokenProvider.notifier).state = null;
              TokenStorage.clear();
              if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(PhosphorIconsRegular.signOut),
            label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.error,
              side: BorderSide(color: cs.error.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        if (role != 'employee') ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Account'),
                    content: const Text('This will permanently delete your account and all associated data. This action cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete', style: TextStyle(color: cs.onError))),
                    ],
                  ),
                );
                if (confirmed != true) return;
                try {
                  await ref.read(authServiceProvider).deleteAccount();
                  ref.read(tokenProvider.notifier).state = null;
                  TokenStorage.clear();
                  if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
                } catch (e) {
                  if (context.mounted) showError(context, e);
                }
              },
              icon: const Icon(PhosphorIconsRegular.trash),
              label: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final ColorScheme cs;
  final String label, value;
  const _InfoRow({required this.cs, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 2, child: Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w500, fontSize: 13))),
        Expanded(flex: 3, child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
      ],
    );
  }
}

class _MyAttendanceTab extends ConsumerWidget {
  final ColorScheme cs;
  final TextTheme tt;
  const _MyAttendanceTab({required this.cs, required this.tt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myAttendanceProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIconsFill.warningCircle, size: 48, color: cs.error),
              const SizedBox(height: 16),
              Text('Something went wrong', style: tt.titleMedium),
              const SizedBox(height: 8),
              Text('$e', style: tt.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(PhosphorIconsFill.arrowClockwise),
                label: const Text('Retry'),
                onPressed: () => ref.invalidate(myAttendanceProvider),
              ),
            ],
          ),
        ),
      ),
      data: (list) {
        final present = list.where((a) => a.status == 'present').length;
        final absent = list.where((a) => a.status == 'absent').length;
        final halfDay = list.where((a) => a.status == 'half_day').length;
        final total = list.length;
        final pct = total > 0 ? present / total : 0.0;

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          children: [
            Row(
              children: [
                _StatBadge(label: 'Present', value: '$present', color: const Color(0xFF10B981)),
                const SizedBox(width: 12),
                _StatBadge(label: 'Absent', value: '$absent', color: const Color(0xFFEF4444)),
                const SizedBox(width: 12),
                _StatBadge(label: 'Half Day', value: '$halfDay', color: const Color(0xFFF59E0B)),
              ],
            ),
            const SizedBox(height: 24),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutExpo,
              builder: (ctx, val, _) => LinearProgressIndicator(
                value: val.clamp(0.0, 1.0),
                backgroundColor: cs.surfaceContainerHighest,
                color: cs.primary,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 24),
            Text('RECORDS (${list.length})', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
            const SizedBox(height: 16),
            if (list.isEmpty)
              Text('No attendance records this month', style: TextStyle(color: cs.onSurfaceVariant))
            else
              for (final att in list.take(20))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (att.status == 'present' ? const Color(0xFF10B981) : att.status == 'absent' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          att.status == 'present' ? PhosphorIconsBold.check : att.status == 'absent' ? PhosphorIconsBold.x : PhosphorIconsBold.minus,
                          size: 14,
                          color: att.status == 'present' ? const Color(0xFF10B981) : att.status == 'absent' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(att.date, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const Spacer(),
                      Text(att.status.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}

class _MyLedgerTab extends ConsumerWidget {
  final ColorScheme cs;
  final TextTheme tt;
  const _MyLedgerTab({required this.cs, required this.tt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myLedgerProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIconsFill.warningCircle, size: 48, color: cs.error),
              const SizedBox(height: 16),
              Text('Something went wrong', style: tt.titleMedium),
              const SizedBox(height: 8),
              Text('$e', style: tt.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(PhosphorIconsFill.arrowClockwise),
                label: const Text('Retry'),
                onPressed: () => ref.invalidate(myLedgerProvider),
              ),
            ],
          ),
        ),
      ),
      data: (data) {
        final balance = (data['balance'] as num?)?.toDouble() ?? 0;
        final entries = (data['entries'] as List<dynamic>?) ?? [];

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3))),
              child: Column(
                children: [
                  Text('OUTSTANDING BALANCE', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  Text('₹${balance.toStringAsFixed(0)}', style: tt.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: cs.primary, letterSpacing: -1.5)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('ENTRIES (${entries.length})', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
            const SizedBox(height: 16),
            if (entries.isEmpty)
              Text('No ledger entries', style: TextStyle(color: cs.onSurfaceVariant))
            else
              for (final e in entries.take(20))
                _LedgerEntryRow(cs: cs, entry: e as Map<String, dynamic>),
          ],
        );
      },
    );
  }
}

class _LedgerEntryRow extends StatelessWidget {
  final ColorScheme cs;
  final Map<String, dynamic> entry;
  const _LedgerEntryRow({required this.cs, required this.entry});

  @override
  Widget build(BuildContext context) {
    final isJama = entry['type'] == 'jama';
    final amount = (entry['amount'] as num?)?.toInt() ?? 0;
    final date = entry['date'] as String? ?? '';
    final color = isJama ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
            child: Icon(isJama ? PhosphorIconsFill.arrowUpRight : PhosphorIconsFill.arrowDownLeft, size: 16, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isJama ? 'Wage Added' : 'Advance Taken', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 2),
              Text(date, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            ],
          ),
          const Spacer(),
          Text('${isJama ? '+' : '-'}₹$amount', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
        ],
      ),
    );
  }
}

class _PayslipTab extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final VoidCallback onDownload;
  final bool isDownloading;
  const _PayslipTab({required this.cs, required this.tt, required this.onDownload, this.isDownloading = false});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(PhosphorIconsFill.fileText, size: 64, color: cs.primary.withValues(alpha: 0.5)),
              const SizedBox(height: 20),
              Text('Monthly Payslip', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Download your payslip for the current month', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: isDownloading ? null : onDownload,
                icon: isDownloading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(PhosphorIconsBold.download),
                label: Text(isDownloading ? 'Downloading...' : 'Download Payslip', style: const TextStyle(fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
