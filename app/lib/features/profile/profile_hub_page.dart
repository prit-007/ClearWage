import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/design_tokens.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/services.dart';
import '../../core/responsive.dart';
import '../../core/widgets/employee_avatar.dart';
import '../../core/currency_format.dart';

final _profileOverviewProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ref.watch(profileServiceProvider).getOverview();
  return res;
});

final _ledgerBalanceProvider =
    FutureProvider.autoDispose<double>((ref) async {
  final balance = await ref.watch(ledgerServiceProvider).getBalance('me');
  return balance;
});

class ProfileHubPage extends ConsumerWidget {
  const ProfileHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final user = ref.watch(userInfoProvider);

    final profileAsync = ref.watch(_profileOverviewProvider);
    final balanceAsync = ref.watch(_ledgerBalanceProvider);

    final overview = profileAsync.valueOrNull;
    final overviewData = (overview?['overview'] as Map<String, dynamic>?) ?? {};
    final profileData =
        (overviewData['profile'] as Map<String, dynamic>?) ?? {};
    final statsData = (overviewData['stats'] as Map<String, dynamic>?) ?? {};

    final name = profileData['name'] as String? ?? '';
    final role = profileData['role'] as String? ?? user?.role ?? '';
    final photoUrl = profileData['photo_url'] as String?;
    final department = profileData['department'] as String? ?? '';
    final outstanding = balanceAsync.valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        child: CustomScrollView(
          physics: AppScrollPhysics.physics(),
          slivers: [
            SliverAppBar(
              backgroundColor: cs.surfaceContainerLowest.withValues(
                alpha: 0.85,
              ),
              pinned: true,
              elevation: 0,
              expandedHeight: 80,
              collapsedHeight: 70,
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
                      'Profile',
                      style: tt.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            cs.primaryContainer.withValues(alpha: 0.6),
                            cs.primaryContainer.withValues(alpha: 0.3),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        children: [
                          EmployeeAvatar(
                            name: name,
                            photoUrl: photoUrl,
                            radius: 36,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            name,
                            style: tt.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: cs.primary,
                              ),
                            ),
                          ),
                          if (department.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              department,
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            cs: cs,
                            tt: tt,
                            icon: PhosphorIconsRegular.clock,
                            label: 'Attendance',
                            value: '${statsData['attendance_rate'] ?? 0}%',
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            cs: cs,
                            tt: tt,
                            icon: PhosphorIconsRegular.currencyInr,
                            label: 'Balance',
                            value: AppCurrency.format(outstanding),
                            color: outstanding > 0
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _SectionHeader(cs: cs, tt: tt, title: 'Account'),
                  _ProfileTile(
                    cs: cs,
                    tt: tt,
                    icon: PhosphorIconsRegular.user,
                    title: 'My Profile',
                    subtitle: 'View and edit your profile',
                    onTap: () => context.push('/my-profile'),
                  ),
                  const SizedBox(height: 20),
                  _SectionHeader(cs: cs, tt: tt, title: 'Financial'),
                  _ProfileTile(
                    cs: cs,
                    tt: tt,
                    icon: PhosphorIconsRegular.currencyInr,
                    title: 'My Ledger',
                    subtitle: outstanding > 0
                        ? '${AppCurrency.format(outstanding)} outstanding'
                        : 'No outstanding balance',
                    onTap: () {
                      final shell = StatefulNavigationShell.of(context);
                      shell.goBranch(3);
                    },
                  ),
                  _ProfileTile(
                    cs: cs,
                    tt: tt,
                    icon: PhosphorIconsRegular.receipt,
                    title: 'Balance Sheet',
                    subtitle: 'Download detailed statement',
                    onTap: () => context.push('/balance-sheet'),
                  ),
                  const SizedBox(height: 20),
                  _SectionHeader(cs: cs, tt: tt, title: 'Support'),
                  _ProfileTile(
                    cs: cs,
                    tt: tt,
                    icon: PhosphorIconsRegular.info,
                    title: 'About',
                    subtitle: 'Factory Workforce v0.7.0',
                    onTap: null,
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'v0.7.0',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.cs,
    required this.tt,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          PhosphorIcon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: tt.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final String title;

  const _SectionHeader({
    required this.cs,
    required this.tt,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: tt.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ProfileTile({
    required this.cs,
    required this.tt,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: PhosphorIcon(icon, size: 18, color: cs.primary),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: tt.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PhosphorIcon(
                  PhosphorIconsRegular.caretRight,
                  size: 14,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
