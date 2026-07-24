import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class EmployeeProfileScreen extends StatefulWidget {
  final String employeeId;
  const EmployeeProfileScreen(
      {super.key, required this.employeeId});
  @override
  State<EmployeeProfileScreen> createState() =>
      _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState
    extends State<EmployeeProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() => HapticFeedback.selectionClick());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: Stack(
        children: [
          NestedScrollView(
            physics: const BouncingScrollPhysics(),
            headerSliverBuilder: (_, _) => [
              SliverAppBar(
                backgroundColor: cs.surfaceContainerLowest,
                elevation: 0,
                pinned: true,
                leading: IconButton(
                  icon: Icon(PhosphorIconsRegular.arrowLeft,
                      color: cs.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Icon(PhosphorIconsRegular.pencilSimple,
                        color: cs.onSurfaceVariant),
                    onPressed: () {},
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 8),
                  child: _EditorialProfileHeader(cs: cs, tt: tt),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _PremiumTabBarDelegate(
                  TabBar(
                    controller: _tabCtrl,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: cs.primaryContainer,
                    ),
                    labelColor: cs.onPrimaryContainer,
                    unselectedLabelColor: cs.onSurfaceVariant,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                    unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    dividerColor: Colors.transparent,
                    splashBorderRadius: BorderRadius.circular(24),
                    tabs: const [
                      Tab(text: 'Info & KYC'),
                      Tab(text: 'Attendance'),
                      Tab(text: 'Ledger'),
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
                _InfoTab(cs: cs, tt: tt),
                _AttendanceTab(cs: cs, tt: tt),
                _LedgerTab(cs: cs, tt: tt),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter:
                    ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.fromLTRB(24, 16, 24,
                      MediaQuery.of(context).padding.bottom + 16),
                  decoration: BoxDecoration(
                    color: cs.surface.withValues(alpha: 0.8),
                    border: Border(
                        top: BorderSide(
                            color: cs.outlineVariant
                                .withValues(alpha: 0.3))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              HapticFeedback.lightImpact(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(16)),
                            side: BorderSide(
                                color: cs.outlineVariant),
                          ),
                          child: const Text('F&F Settle',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              HapticFeedback.heavyImpact(),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(16)),
                          ),
                          child: const Text('Generate Slip',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorialProfileHeader extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  const _EditorialProfileHeader(
      {required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: cs.primary.withValues(alpha: 0.2),
                  width: 2)),
          child: CircleAvatar(
            radius: 48,
            backgroundColor: cs.primaryContainer,
            child: Text('RS',
                style: tt.headlineMedium?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 16),
        Text('Rahul Sharma',
            style: tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text('Operator · Production',
            style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PremiumActionButton(
                cs: cs,
                icon: PhosphorIconsFill.phone,
                label: 'Call',
                color: const Color(0xFF10B981)),
            const SizedBox(width: 16),
            _PremiumActionButton(
                cs: cs,
                icon: PhosphorIconsFill.whatsappLogo,
                label: 'WhatsApp',
                color: const Color(0xFF128C7E)),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _PremiumActionButton extends StatelessWidget {
  final ColorScheme cs;
  final IconData icon;
  final String label;
  final Color color;

  const _PremiumActionButton(
      {required this.cs,
      required this.icon,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => HapticFeedback.selectionClick(),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _PremiumTabBarDelegate
    extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color bgColor;
  _PremiumTabBarDelegate(this.tabBar, this.bgColor);

  @override
  Widget build(BuildContext context, _, _) => Container(
        color: bgColor,
        padding: const EdgeInsets.only(bottom: 8),
        child: tabBar,
      );
  @override
  double get maxExtent => 56;
  @override
  double get minExtent => 56;
  @override
  bool shouldRebuild(_) => false;
}

class _InfoTab extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  const _InfoTab({required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _EditorialInfoBlock(
            cs: cs,
            tt: tt,
            title: 'Employment Details',
            data: {
              'Employee ID': 'EMP-042',
              'Department': 'Production',
              'Date of Joining': '12 Mar 2023',
            }),
        _EditorialInfoBlock(
            cs: cs,
            tt: tt,
            title: 'Financial Config',
            data: {
              'Wage Type': 'Daily Wage',
              'Base Rate': '₹450 / day',
              'Bank Account': 'XXXX-XXXX-4821',
            }),
      ],
    );
  }
}

class _EditorialInfoBlock extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final String title;
  final Map<String, String> data;

  const _EditorialInfoBlock(
      {required this.cs,
      required this.tt,
      required this.title,
      required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: tt.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color:
                      cs.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                for (int i = 0; i < entries.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                        bottom: i < entries.length - 1 ? 16 : 0),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 2,
                            child: Text(entries[i].key,
                                style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500))),
                        Expanded(
                            flex: 3,
                            child: Text(entries[i].value,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceTab extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  const _AttendanceTab({required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _AttMacroStat(
                tt: tt,
                label: 'Present',
                value: '22',
                color: const Color(0xFF10B981)),
            _AttMacroStat(
                tt: tt,
                label: 'Absent',
                value: '2',
                color: const Color(0xFFEF4444)),
            _AttMacroStat(
                tt: tt,
                label: 'Half',
                value: '1',
                color: const Color(0xFFF59E0B)),
          ],
        ),
        const SizedBox(height: 24),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 22 / 26),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutExpo,
          builder: (context, val, _) => LinearProgressIndicator(
            value: val,
            backgroundColor: cs.surfaceContainerHighest,
            color: const Color(0xFF10B981),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 32),
        Text('RECENT LOGS',
            style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0)),
        const SizedBox(height: 16),
        ...List.generate(
            5,
            (i) => _TimelineRow(
                cs: cs,
                isPresent: i < 4,
                date: '${24 - i} Oct 2026')),
      ],
    );
  }
}

class _AttMacroStat extends StatelessWidget {
  final TextTheme tt;
  final String label, value;
  final Color color;
  const _AttMacroStat(
      {required this.tt,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: tt.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -1.0,
                height: 1.0)),
        const SizedBox(height: 4),
        Text(label.toUpperCase(),
            style: tt.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color.withValues(alpha: 0.8))),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final ColorScheme cs;
  final bool isPresent;
  final String date;

  const _TimelineRow(
      {required this.cs,
      required this.isPresent,
      required this.date});

  @override
  Widget build(BuildContext context) {
    final color = isPresent
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: Icon(
                isPresent
                    ? PhosphorIconsBold.check
                    : PhosphorIconsBold.x,
                size: 14,
                color: color),
          ),
          const SizedBox(width: 16),
          Text(date,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          const Spacer(),
          Text(isPresent ? 'Present' : 'Absent',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _LedgerTab extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  const _LedgerTab({required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Text('NET OUTSTANDING',
            style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Text('₹27,300',
            style: tt.displayMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: cs.primary,
                letterSpacing: -1.5)),
        const SizedBox(height: 32),
        Text('RECENT ENTRIES',
            style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0)),
        const SizedBox(height: 16),
        ...List.generate(
            5,
            (i) => _LedgerEntryRow(
                cs: cs,
                isJama: i.isEven,
                amount: i.isEven ? 450 : 1500,
                date: '${24 - i} Oct 2026')),
      ],
    );
  }
}

class _LedgerEntryRow extends StatelessWidget {
  final ColorScheme cs;
  final bool isJama;
  final int amount;
  final String date;

  const _LedgerEntryRow(
      {required this.cs,
      required this.isJama,
      required this.amount,
      required this.date});

  @override
  Widget build(BuildContext context) {
    final color = isJama
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: cs.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(
                isJama
                    ? PhosphorIconsFill.arrowUpRight
                    : PhosphorIconsFill.arrowDownLeft,
                size: 16,
                color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  isJama
                      ? 'Wage Added'
                      : 'Advance Taken',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              const SizedBox(height: 2),
              Text(date,
                  style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12)),
            ],
          ),
          const Spacer(),
          Text('${isJama ? '+' : '-'}₹$amount',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
        ],
      ),
    );
  }
}
