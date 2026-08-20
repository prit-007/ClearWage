import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/token_storage.dart';
import '../../data/models/attendance_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/services.dart';
import '../../core/helpers.dart';
import '../../core/widgets/fluid_slide_in.dart';
import '../../core/widgets/employee_avatar.dart';
import '../../core/responsive.dart';
import '../../core/design_tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/currency_format.dart';
import 'dart:async';

final myProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
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

final myAttendanceProvider = FutureProvider.autoDispose<List<Attendance>>((
  ref,
) {
  final now = DateTime.now();
  final start = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
  final end =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  return ref
      .watch(profileServiceProvider)
      .getAttendance(start: start, end: end);
});

final myLedgerProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) {
  final now = DateTime.now();
  final start = '${now.year}-01-01';
  final end =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  return ref.watch(profileServiceProvider).getLedger(start: start, end: end);
});

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});
  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  bool _downloading = false;
  bool _uploadingPhoto = false;
  late DateTime _payslipMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _payslipMonth = DateTime(now.year, now.month);
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
    unawaited(HapticFeedback.selectionClick());
    final source = await showAdaptiveSheet<String>(
      context: context,
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
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: PhosphorIcon(
                  PhosphorIconsDuotone.camera,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text(
                  'Capture with Camera',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: PhosphorIcon(
                  PhosphorIconsDuotone.image,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
    unawaited(HapticFeedback.heavyImpact());
    setState(() => _downloading = true);
    try {
      final year = _payslipMonth.year;
      final month = _payslipMonth.month;
      final lastDay = DateTime(year, month + 1, 0).day;
      final now = DateTime.now();
      final endDay = (year == now.year && month == now.month)
          ? now.day
          : lastDay;
      final start = '$year-${month.toString().padLeft(2, '0')}-01';
      final end =
          '$year-${month.toString().padLeft(2, '0')}-${endDay.toString().padLeft(2, '0')}';
      final client = ref.read(apiClientProvider);
      final bytes = await client.getRaw(
        '/api/v1/me/payslip',
        query: {'start_date': start, 'end_date': end},
      );
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/payslip_$start.pdf');
      await file.writeAsBytes(bytes);
      if (mounted) {
        final opened = await launchUrl(
          Uri.file(file.path),
          mode: LaunchMode.externalApplication,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                opened
                    ? 'Payslip opened'
                    : 'Payslip saved. Could not open automatically.',
              ),
            ),
          );
        }
      }
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
      body: ref
          .watch(myProfileProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PhosphorIcon(
                      PhosphorIconsDuotone.warningCircle,
                      size: 56,
                      color: cs.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Something went wrong',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$e',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      icon: const Icon(
                        PhosphorIconsBold.arrowClockwise,
                        size: 18,
                      ),
                      label: const Text(
                        'Retry',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => ref.invalidate(myProfileProvider),
                    ),
                  ],
                ),
              ),
            ),
            data: (data) {
              final name = data['name'] as String? ?? 'User';
              final role = data['role'] as String? ?? '';
              final employeeId = data['id'] as String? ?? '';

              return NestedScrollView(
                physics: AppScrollPhysics.physics(),
                headerSliverBuilder: (_, _) => [
                  SliverAppBar(
                    backgroundColor: cs.surfaceContainerLowest.withValues(
                      alpha: 0.85,
                    ),
                    elevation: 0,
                    pinned: true,
                    expandedHeight: 100,
                    flexibleSpace: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: AppBlur.sigma,
                          sigmaY: AppBlur.sigma,
                        ),
                        child: FlexibleSpaceBar(
                          titlePadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          centerTitle: true,
                          title: Text(
                            'Account',
                            style: tt.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    leading: IconButton(
                      icon: Icon(
                        PhosphorIconsRegular.arrowLeft,
                        color: cs.onSurface,
                      ),
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
                              border: Border.all(
                                color: cs.primary.withValues(alpha: 0.2),
                                width: 3,
                              ),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                EmployeeAvatar(
                                  name: name,
                                  photoUrl: data['photo_url'] as String?,
                                  radius: 56,
                                  backgroundColor: cs.primaryContainer
                                      .withValues(alpha: 0.5),
                                  textColor: cs.primary,
                                  fontSize: 28,
                                ),
                                if (employeeId.isNotEmpty)
                                  Positioned(
                                    right: -4,
                                    bottom: -4,
                                    child: GestureDetector(
                                      onTap: _uploadingPhoto
                                          ? null
                                          : () =>
                                                _pickAndUploadPhoto(employeeId),
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: cs.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: cs.surfaceContainerLowest,
                                            width: 3,
                                          ),
                                        ),
                                        child: _uploadingPhoto
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : Icon(
                                                PhosphorIconsFill.camera,
                                                size: 16,
                                                color: cs.onPrimary,
                                              ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            name,
                            style: tt.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TabBarDelegate(
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TabBar(
                          controller: _tabCtrl,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: cs.surface,
                            boxShadow: [
                              BoxShadow(
                                color: cs.shadow.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          labelColor: cs.primary,
                          unselectedLabelColor: cs.onSurfaceVariant,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
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
                  physics: AppScrollPhysics.physics(),
                  children: [
                    _ProfileTab(cs: cs, tt: tt, data: data),
                    _MyAttendanceTab(cs: cs, tt: tt),
                    _MyLedgerTab(cs: cs, tt: tt),
                    _PayslipTab(
                      cs: cs,
                      tt: tt,
                      onDownload: _downloadPayslip,
                      isDownloading: _downloading,
                      payslipMonth: _payslipMonth,
                      onMonthChanged: (m) => setState(() => _payslipMonth = m),
                    ),
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
  Widget build(BuildContext context, _, _) =>
      Container(color: bgColor, child: tabBar);
  @override
  double get maxExtent => 64;
  @override
  double get minExtent => 64;
  @override
  bool shouldRebuild(_TabBarDelegate old) =>
      old.tabBar != tabBar || old.bgColor != bgColor;
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
    final factoryName =
        ((data['factory_name'] as String?)?.isNotEmpty == true
            ? data['factory_name'] as String
            : data['tenant_name'] as String?) ??
        '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      children: [
        FluidSlideIn(
          delay: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                _InfoRow(cs: cs, label: 'Phone', value: phone),
                Divider(
                  height: 32,
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
                _InfoRow(
                  cs: cs,
                  label: 'Email',
                  value: email.isNotEmpty ? email : 'Not assigned',
                ),
                Divider(
                  height: 32,
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
                _InfoRow(cs: cs, label: 'System Role', value: role),
                Divider(
                  height: 32,
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
                _InfoRow(
                  cs: cs,
                  label: 'Workspace',
                  value: factoryName.isNotEmpty ? factoryName : 'Unknown',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        FluidSlideIn(
          delay: 100,
          child: FilledButton.icon(
            onPressed: () async {
              final confirmed = await showConfirmDialog(
                context,
                title: 'Sign Out',
                message: 'Are you sure you want to end your current session?',
                confirmLabel: 'Sign Out',
                icon: PhosphorIconsRegular.signOut,
                isDestructive: true,
              );
              if (confirmed != true) return;
              await ref.read(authServiceProvider).logout();
              ref.read(tokenProvider.notifier).state = null;
              await TokenStorage.clear();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(PhosphorIconsRegular.signOut),
            label: const Text(
              'Sign Out',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        if (role != 'employee') ...[
          const SizedBox(height: 16),
          FluidSlideIn(
            delay: 150,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showConfirmDialog(
                  context,
                  title: 'Delete Account',
                  message:
                      'Are you sure you want to delete your account? This action cannot be undone.',
                  confirmLabel: 'Delete',
                  icon: PhosphorIconsRegular.warningCircle,
                  isDestructive: true,
                );
                if (confirmed != true) return;
                try {
                  await ref.read(authServiceProvider).deleteAccount();
                  ref.read(tokenProvider.notifier).state = null;
                  await TokenStorage.clear();
                  if (context.mounted) context.go('/login');
                } catch (e) {
                  if (context.mounted) showError(context, e);
                }
              },
              icon: const Icon(PhosphorIconsRegular.trash),
              label: const Text(
                'Delete Account',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
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
    final attendanceAsync = ref.watch(myAttendanceProvider);
    return attendanceAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(
                PhosphorIconsDuotone.warningCircle,
                size: 48,
                color: cs.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                '$e',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(PhosphorIconsBold.arrowClockwise),
                label: const Text(
                  'Retry',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
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
        final pct = total > 0 ? (present + halfDay * 0.5) / total : 0.0;

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          children: [
            FluidSlideIn(
              delay: 0,
              child: Row(
                children: [
                  _StatBadge(
                    label: 'Present',
                    value: '$present',
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 12),
                  _StatBadge(
                    label: 'Absent',
                    value: '$absent',
                    color: AppColors.danger,
                  ),
                  const SizedBox(width: 12),
                  _StatBadge(
                    label: 'Half Day',
                    value: '$halfDay',
                    color: AppColors.warning,
                  ),
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
            FluidSlideIn(
              delay: 200,
              child: Text(
                'RECORDS (${list.length})',
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (list.isEmpty)
              const EmptyState(
                icon: PhosphorIconsRegular.calendarBlank,
                title: 'No attendance records this month',
              )
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
                            color:
                                (list[i].status == 'present'
                                        ? AppColors.success
                                        : list[i].status == 'absent'
                                        ? AppColors.danger
                                        : AppColors.warning)
                                    .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            list[i].status == 'present'
                                ? PhosphorIconsBold.check
                                : list[i].status == 'absent'
                                ? PhosphorIconsBold.x
                                : PhosphorIconsBold.minus,
                            size: 16,
                            color: list[i].status == 'present'
                                ? AppColors.success
                                : list[i].status == 'absent'
                                ? AppColors.danger
                                : AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          formatDate(list[i].date),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          list[i].status.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 0.5,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
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
  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 28,
                color: color,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
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
    final ledgerAsync = ref.watch(myLedgerProvider);
    return ledgerAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(
                PhosphorIconsDuotone.warningCircle,
                size: 48,
                color: cs.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                '$e',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(PhosphorIconsBold.arrowClockwise),
                label: const Text(
                  'Retry',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
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
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OUTSTANDING BALANCE',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppCurrency.format(balance.abs()),
                      style: tt.displayLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.primary,
                        letterSpacing: -2.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            FluidSlideIn(
              delay: 100,
              child: Text(
                'ENTRIES (${entries.length})',
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (entries.isEmpty)
              const EmptyState(
                icon: PhosphorIconsRegular.receipt,
                title: 'No ledger entries',
              )
            else
              for (int i = 0; i < entries.take(20).length; i++)
                FluidSlideIn(
                  delay: 150 + (i * 50).clamp(0, 400).toInt(),
                  child: _LedgerEntryRow(
                    cs: cs,
                    entry: entries[i] as Map<String, dynamic>,
                  ),
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
    final color = isJama ? AppColors.success : AppColors.danger;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isJama
                  ? PhosphorIconsBold.arrowUpRight
                  : PhosphorIconsBold.arrowDownLeft,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isJama ? 'Wage Added' : 'Advance Taken',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatDate(date),
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            '${isJama ? '+' : '-'}\u20B9${amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: -0.5,
            ),
          ),
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
  final DateTime payslipMonth;
  final ValueChanged<DateTime> onMonthChanged;
  const _PayslipTab({
    required this.cs,
    required this.tt,
    required this.onDownload,
    this.isDownloading = false,
    required this.payslipMonth,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth =
        payslipMonth.year == now.year && payslipMonth.month == now.month;
    final monthNames = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
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
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: PhosphorIcon(
                    PhosphorIconsDuotone.fileText,
                    size: 48,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Monthly Payslip',
                  style: tt.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => onMonthChanged(
                        DateTime(payslipMonth.year, payslipMonth.month - 1),
                      ),
                      icon: Icon(
                        PhosphorIconsRegular.caretLeft,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        '${monthNames[payslipMonth.month]} ${payslipMonth.year}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: isCurrentMonth
                          ? null
                          : () => onMonthChanged(
                              DateTime(
                                payslipMonth.year,
                                payslipMonth.month + 1,
                              ),
                            ),
                      icon: Icon(
                        PhosphorIconsRegular.caretRight,
                        color: isCurrentMonth
                            ? cs.outlineVariant
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Download a detailed breakdown of your attendance, wages, and advances for this month.',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: isDownloading ? null : onDownload,
                  icon: isDownloading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(PhosphorIconsBold.download),
                  label: Text(
                    isDownloading ? 'Generating PDF...' : 'Download Payslip',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
