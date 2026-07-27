import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../providers/providers.dart';
import '../../models/employee_model.dart';
import '../../core/helpers.dart';
import '../../core/widgets/bottom_blur_bar.dart';
import 'add_employee_page.dart';

class EmployeeProfileScreen extends ConsumerStatefulWidget {
  final String employeeId;
  const EmployeeProfileScreen(
      {super.key, required this.employeeId});
  @override
  ConsumerState<EmployeeProfileScreen> createState() =>
      _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState
    extends ConsumerState<EmployeeProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>>? _attendance;
  List<Map<String, dynamic>>? _ledger;
  double? _balance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() => HapticFeedback.selectionClick());
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final now = DateTime.now();
    final start = '${now.year}-01-01';
    final end = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    Map<String, dynamic>? data;
    Map<String, dynamic>? empJson;
    try {
      data = await ref.read(staffServiceProvider).getProfile(widget.employeeId);
    } catch (e) {
      if (mounted) showError(context, e);
    }
    try {
      empJson = (await ref.read(staffServiceProvider).get(widget.employeeId)).toJson();
    } catch (e) {
      if (mounted) showError(context, e);
    }
    List<Map<String, dynamic>>? attList;
    try {
      final list = await ref.read(attendanceServiceProvider).listByEmployee(widget.employeeId, startDate: start, endDate: end);
      attList = list.map((a) => a.toJson()).toList();
    } catch (e) {
      debugPrint('Failed to load attendance: $e');
    }
    List<Map<String, dynamic>>? ledgerList;
    try {
      final list = await ref.read(ledgerServiceProvider).listByEmployee(widget.employeeId, startDate: start, endDate: end);
      ledgerList = list.map((l) => l.toJson()).toList();
    } catch (e) {
      debugPrint('Failed to load ledger: $e');
    }
    double? bal;
    try { bal = await ref.read(ledgerServiceProvider).getBalance(widget.employeeId); } catch (e) { debugPrint('Failed to load balance: $e'); }
    if (mounted) {
      setState(() {
        _profile = data ?? empJson;
        if (data != null && empJson != null) _profile = {...data, ...empJson};
        _attendance = attList;
        _ledger = ledgerList;
        _balance = bal;
        _loading = false;
      });
    }
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

    if (_loading) {
      return Scaffold(
        backgroundColor: cs.surfaceContainerLowest,
        appBar: AppBar(
          backgroundColor: cs.surfaceContainerLowest,
          elevation: 0,
          leading: IconButton(
            icon: Icon(PhosphorIconsRegular.arrowLeft, color: cs.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final name = _profile?['name'] as String? ?? 'Employee';
    final role = _profile?['role'] as String? ?? '';
    final designation = _profile?['designation'] as String? ?? role;
    final phone = _profile?['phone'] as String? ?? '';
    final initials = getInitials(name);

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
                    onPressed: () async {
                      final emp = _profile;
                      if (emp == null || emp['id'] == null) return;
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEmployeeScreen(
                            employee: Employee.fromJson(emp),
                          ),
                        ),
                      );
                      if (result == true && mounted) _loadProfile();
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 8),
                  child: _EditorialProfileHeader(cs: cs, tt: tt, name: name, initials: initials, designation: designation, phone: phone),
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
                _InfoTab(cs: cs, tt: tt, profile: _profile),
                _AttendanceTab(cs: cs, tt: tt, attendanceList: _attendance),
                _LedgerTab(cs: cs, tt: tt, ledgerList: _ledger, balance: _balance),
              ],
            ),
          ),
          BottomBlurBar(
            child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Settle Account'),
                                content: const Text('This will zero out the outstanding balance. This action cannot be undone.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Settle')),
                                ],
                              ),
                            );
                            if (confirmed != true) return;
                            HapticFeedback.lightImpact();
                            try {
                              await ref.read(ledgerServiceProvider).settleAccount(widget.employeeId);
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account settled')));
                              if (mounted) _loadProfile();
                            } catch (e) {
                              if (context.mounted) showError(context, e);
                            }
                          },
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
                          onPressed: () async {
                            HapticFeedback.heavyImpact();
                            try {
                              final now = DateTime.now();
                              final start = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
                              final end = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                              await ref.read(payrollServiceProvider).generatePayslip(employeeId: widget.employeeId, startDate: start, endDate: end);
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payslip generated')));
                            } catch (e) {
                              if (context.mounted) showError(context, e);
                            }
                          },
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
        ],
      ),
    );
  }
}

class _EditorialProfileHeader extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final String name, initials, designation, phone;
  const _EditorialProfileHeader({
    required this.cs, required this.tt,
    required this.name, required this.initials,
    required this.designation, required this.phone,
  });

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
            child: Text(initials,
                style: tt.headlineMedium?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 16),
        Text(name,
            style: tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(designation,
            style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 24),
      ],
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
  final Map<String, dynamic>? profile;
  const _InfoTab({required this.cs, required this.tt, this.profile});

  @override
  Widget build(BuildContext context) {
    final wageType = profile?['wage_type'] as String? ?? '';
    final wageAmount = profile?['wage_amount']?.toString() ?? '0';
    final designation = profile?['designation'] as String? ?? profile?['role'] as String? ?? '';
    final manager = profile?['manager_name'] as String? ?? 'Not assigned';
    final shiftName = profile?['shift_name'] as String? ?? 'Not assigned';

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 160),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _EditorialInfoBlock(
            cs: cs,
            tt: tt,
            title: 'Employment Details',
            data: {
              'Designation': designation,
              'Shift': shiftName,
              'Manager': manager,
            }),
        _EditorialInfoBlock(
            cs: cs,
            tt: tt,
            title: 'Financial Config',
            data: {
              'Wage Type': wageType == 'daily' ? 'Daily Wage' : wageType == 'monthly' ? 'Monthly' : wageType,
              'Base Rate': '₹$wageAmount${wageType == 'daily' ? ' / day' : ''}',
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
  final List<Map<String, dynamic>>? attendanceList;
  const _AttendanceTab({required this.cs, required this.tt, this.attendanceList});

  @override
  Widget build(BuildContext context) {
    final list = attendanceList ?? [];
    final present = list.where((a) => a['status'] == 'present').length;
    final absent = list.where((a) => a['status'] == 'absent').length;
    final halfDay = list.where((a) => a['status'] == 'half_day').length;
    final total = list.isNotEmpty ? list.length : 1;
    final pct = total > 0 ? present / total : 0.0;
    final recent = list.take(5).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 160),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _AttMacroStat(
                tt: tt,
                label: 'Present',
                value: '$present',
                color: const Color(0xFF10B981)),
            _AttMacroStat(
                tt: tt,
                label: 'Absent',
                value: '$absent',
                color: const Color(0xFFEF4444)),
            _AttMacroStat(
                tt: tt,
                label: 'Half',
                value: '$halfDay',
                color: const Color(0xFFF59E0B)),
          ],
        ),
        const SizedBox(height: 24),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: pct),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutExpo,
          builder: (context, val, _) => LinearProgressIndicator(
            value: val.clamp(0.0, 1.0),
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
        if (recent.isEmpty)
          Text('No attendance records', style: TextStyle(color: cs.onSurfaceVariant))
        else
          ...recent.map((a) => _TimelineRow(
              cs: cs,
              isPresent: a['status'] == 'present',
              date: a['date'] as String? ?? '')),
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
  final List<Map<String, dynamic>>? ledgerList;
  final double? balance;
  const _LedgerTab({required this.cs, required this.tt, this.ledgerList, this.balance});

  @override
  Widget build(BuildContext context) {
    final list = ledgerList ?? [];
    final bal = balance ?? 0;
    final recent = list.take(5).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 160),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Text('NET OUTSTANDING',
            style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Text('₹${bal.toStringAsFixed(0)}',
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
        if (recent.isEmpty)
          Text('No ledger entries', style: TextStyle(color: cs.onSurfaceVariant))
        else
          ...recent.map((e) => _LedgerEntryRow(
              cs: cs,
              isJama: e['type'] == 'jama',
              amount: (e['amount'] as num?)?.toInt() ?? 0,
              date: e['date'] as String? ?? '')),
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
