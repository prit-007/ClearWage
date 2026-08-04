import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../core/token_storage.dart';
import '../../core/app_config.dart';
import '../../models/attendance_model.dart';
import '../../providers/providers.dart';
import '../../core/helpers.dart';
import '../../core/widgets/fluid_slide_in.dart';

final myProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ref.watch(profileServiceProvider).getOverview();
  final overview = (res['overview'] as Map<String, dynamic>?) ?? {};
  final profile = (overview['profile'] as Map<String, dynamic>?) ?? {};
  final tenant = (res['tenant'] as Map<String, dynamic>?) ?? {};
  return <String, dynamic>{
    ...profile,
    'factory_name': tenant['name'],
    'tenant_name': tenant['name'],
    'email': profile['email'],
  };
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
  bool _uploadingPhoto = false;

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

  Future<void> _pickAndUploadPhoto(String employeeId) async {
    HapticFeedback.selectionClick();
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              ListTile(
                leading: PhosphorIcon(PhosphorIconsDuotone.camera, color: Theme.of(context).colorScheme.primary),
                title: const Text('Capture with Camera', style: TextStyle(fontWeight: FontWeight.w700)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: PhosphorIcon(PhosphorIconsDuotone.image, color: Theme.of(context).colorScheme.primary),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w700)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;

    String? path;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      path = picked?.path;
    } catch (_) {
      if (mounted) showError(context, 'Could not pick photo');
      return;
    }
    if (path == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      await ref.read(staffServiceProvider).uploadPhoto(employeeId, path);
      if (mounted) {
        showSuccess(context, 'Photo updated');
        ref.invalidate(myProfileProvider);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
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
      body: ref.watch(myProfileProvider).when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PhosphorIcon(PhosphorIconsDuotone.warningCircle, size: 56, color: cs.error),
                const SizedBox(height: 16),
                Text('Something went wrong', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('$e', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(PhosphorIconsBold.arrowClockwise, size: 18),
                  label: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700)),
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
          final photoUrl = resolveMediaUrl(data['photo_url'] as String? ?? '', ref.watch(serverUrlProvider));
          final employeeId = data['id'] as String? ?? '';

          return NestedScrollView(
            physics: const BouncingScrollPhysics(),
            headerSliverBuilder: (_, _) => [
              SliverAppBar(
                backgroundColor: cs.surfaceContainerLowest.withValues(alpha: 0.85),
                elevation: 0,
                pinned: true,
                expandedHeight: 100,
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      centerTitle: true,
                      title: Text('Account', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: Icon(PhosphorIconsRegular.arrowLeft, color: cs.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.primary.withValues(alpha: 0.2), width: 3),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 56,
                              backgroundColor: cs.primaryContainer.withValues(alpha: 0.5),
                              backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                              child: photoUrl.isNotEmpty
                                  ? null
                                  : Text(initials, style: tt.headlineMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w900, letterSpacing: -1.0)),
                            ),
                            if (employeeId.isNotEmpty)
                              Positioned(
                                right: -4,
                                bottom: -4,
                                child: GestureDetector(
                                  onTap: _uploadingPhoto ? null : () => _pickAndUploadPhoto(employeeId),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: cs.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: cs.surfaceContainerLowest, width: 3),
                                    ),
                                    child: _uploadingPhoto
                                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : Icon(PhosphorIconsFill.camera, size: 16, color: cs.onPrimary),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(name, style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1.0)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(12)),
                        child: Text(role.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: cs.primary)),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TabBar(
                      controller: _tabCtrl,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: cs.surface,
                        boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      labelColor: cs.primary,
                      unselectedLabelColor: cs.onSurfaceVariant,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      dividerColor: Colors.transparent,
                      isScrollable: true,
                      tabAlignment: TabAlignment.center,
                      tabs: const [
                        Tab(text: 'Details'),
                        Tab(text: 'Attendance'),
                        Tab(text: 'Ledger'),
                        Tab(text: 'Payslips'),
                      ],
                    ),
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
  final Widget tabBar;
  final Color bgColor;
  _TabBarDelegate(this.tabBar, this.bgColor);

  @override
  Widget build(BuildContext context, _, _) => Container(color: bgColor, child: tabBar);
  @override
  double get maxExtent => 64;
  @override
  double get minExtent => 64;
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
    final factoryName = ((data['factory_name'] as String?)?.isNotEmpty == true
        ? data['factory_name'] as String
        : data['tenant_name'] as String?) ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      children: [
        FluidSlideIn(
          delay: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3))),
            child: Column(
              children: [
                _InfoRow(cs: cs, label: 'Phone', value: phone),
                Divider(height: 32, color: cs.outlineVariant.withValues(alpha: 0.3)),
                _InfoRow(cs: cs, label: 'Email', value: email.isNotEmpty ? email : 'Not assigned'),
                Divider(height: 32, color: cs.outlineVariant.withValues(alpha: 0.3)),
                _InfoRow(cs: cs, label: 'System Role', value: role),
                Divider(height: 32, color: cs.outlineVariant.withValues(alpha: 0.3)),
                _InfoRow(cs: cs, label: 'Workspace', value: factoryName.isNotEmpty ? factoryName : 'Unknown'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        FluidSlideIn(
          delay: 100,
          child: OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800)),
                  content: const Text('Are you sure you want to end your current session?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700))),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: cs.error), child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700))),
                  ],
                ),
              );
              if (confirmed != true) return;
              await ref.read(authServiceProvider).logout();
              ref.read(tokenProvider.notifier).state = null;
              await TokenStorage.clear();
              if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(PhosphorIconsRegular.signOut),
            label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800)),
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.error,
              side: BorderSide(color: cs.error.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        if (role != 'employee') ...[
          const SizedBox(height: 16),
          FluidSlideIn(
            delay: 150,
            child: FilledButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.w800)),
                    content: const Text('This will permanently delete your account and all associated data. This action cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700))),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: cs.error), child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700))),
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
              label: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.w800)),
              style: FilledButton.styleFrom(
                backgroundColor: cs.error.withValues(alpha: 0.1),
                foregroundColor: cs.error,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 18),
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
        Expanded(flex: 2, child: Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600, fontSize: 13))),
        Expanded(flex: 3, child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
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
              PhosphorIcon(PhosphorIconsDuotone.warningCircle, size: 48, color: cs.error),
              const SizedBox(height: 16),
              Text('Something went wrong', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('$e', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(PhosphorIconsBold.arrowClockwise),
                label: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700)),
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
            FluidSlideIn(
              delay: 0,
              child: Row(
                children: [
                  _StatBadge(label: 'Present', value: '$present', color: const Color(0xFF10B981)),
                  const SizedBox(width: 12),
                  _StatBadge(label: 'Absent', value: '$absent', color: const Color(0xFFEF4444)),
                  const SizedBox(width: 12),
                  _StatBadge(label: 'Half Day', value: '$halfDay', color: const Color(0xFFF59E0B)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FluidSlideIn(
              delay: 100,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: pct),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutExpo,
                builder: (ctx, val, _) => LinearProgressIndicator(
                  value: val.clamp(0.0, 1.0),
                  backgroundColor: cs.surfaceContainerHighest,
                  color: cs.primary,
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(height: 32),
            FluidSlideIn(delay: 200, child: Text('RECORDS (${list.length})', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w900, letterSpacing: 1.0))),
            const SizedBox(height: 16),
            if (list.isEmpty)
              FluidSlideIn(delay: 250, child: Text('No attendance records this month', style: TextStyle(color: cs.onSurfaceVariant)))
            else
              for (int i = 0; i < list.take(20).length; i++)
                FluidSlideIn(
                  delay: 250 + (i * 50).clamp(0, 400).toInt(),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (list[i].status == 'present' ? const Color(0xFF10B981) : list[i].status == 'absent' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            list[i].status == 'present' ? PhosphorIconsBold.check : list[i].status == 'absent' ? PhosphorIconsBold.x : PhosphorIconsBold.minus,
                            size: 16,
                            color: list[i].status == 'present' ? const Color(0xFF10B981) : list[i].status == 'absent' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(list[i].date, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        const Spacer(),
                        Text(list[i].status.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5, color: cs.onSurfaceVariant)),
                      ],
                    ),
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
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28, color: color, letterSpacing: -1.0)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: color, letterSpacing: 0.5)),
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
              PhosphorIcon(PhosphorIconsDuotone.warningCircle, size: 48, color: cs.error),
              const SizedBox(height: 16),
              Text('Something went wrong', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('$e', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(PhosphorIconsBold.arrowClockwise),
                label: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: () => ref.invalidate(myLedgerProvider),
              ),
            ],
          ),
        ),
      ),
      data: (data) {
        final balance = safeToDouble(data['balance']);
        final entries = (data['entries'] as List<dynamic>?) ?? [];

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          children: [
            FluidSlideIn(
              delay: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)), boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('OUTSTANDING BALANCE', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                    const SizedBox(height: 8),
                    Text('₹${balance.abs().toStringAsFixed(0)}', style: tt.displayLarge?.copyWith(fontWeight: FontWeight.w900, color: cs.primary, letterSpacing: -2.0)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            FluidSlideIn(delay: 100, child: Text('ENTRIES (${entries.length})', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w900, letterSpacing: 1.0))),
            const SizedBox(height: 16),
            if (entries.isEmpty)
              FluidSlideIn(delay: 150, child: Text('No ledger entries', style: TextStyle(color: cs.onSurfaceVariant)))
            else
              for (int i = 0; i < entries.take(20).length; i++)
                FluidSlideIn(
                  delay: 150 + (i * 50).clamp(0, 400).toInt(),
                  child: _LedgerEntryRow(cs: cs, entry: entries[i] as Map<String, dynamic>),
                ),
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
    final amount = safeToDouble(entry['amount']);
    final date = entry['date'] as String? ?? '';
    final color = isJama ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
            child: Icon(isJama ? PhosphorIconsBold.arrowUpRight : PhosphorIconsBold.arrowDownLeft, size: 18, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isJama ? 'Wage Added' : 'Advance Taken', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 4),
              Text(date, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const Spacer(),
          Text('${isJama ? '+' : '-'}\u20B9${amount.toStringAsFixed(0)}', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
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
        FluidSlideIn(
          delay: 0,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.5), shape: BoxShape.circle),
                  child: PhosphorIcon(PhosphorIconsDuotone.fileText, size: 48, color: cs.primary),
                ),
                const SizedBox(height: 24),
                Text('Monthly Payslip', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 8),
                Text('Download a detailed breakdown of your attendance, wages, and advances for the current month.', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: isDownloading ? null : onDownload,
                  icon: isDownloading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(PhosphorIconsBold.download),
                  label: Text(isDownloading ? 'Generating PDF...' : 'Download Payslip', style: const TextStyle(fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
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
