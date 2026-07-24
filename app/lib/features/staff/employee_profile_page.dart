import 'package:flutter/material.dart';

class EmployeeProfileScreen extends StatefulWidget {
  final String employeeId;
  const EmployeeProfileScreen({super.key, required this.employeeId});
  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
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
      appBar: AppBar(title: const Text('Profile')),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                CircleAvatar(
                  radius: 44,
                  backgroundColor: cs.primaryContainer,
                  child: Text('RS', style: tt.headlineMedium?.copyWith(
                    color: cs.onPrimaryContainer,
                  )),
                ),
                const SizedBox(height: 12),
                Text('Rahul Sharma', style: tt.headlineSmall),
                const SizedBox(height: 4),
                Text('Operator - Production', style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                )),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () {},
                      icon: const Icon(Icons.phone, size: 18),
                      label: const Text('Call'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonalIcon(
                      onPressed: () {},
                      icon: const Icon(Icons.message, size: 18),
                      label: const Text('Message'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabCtrl,
                tabs: const [
                  Tab(text: 'Info'),
                  Tab(text: 'Attendance'),
                  Tab(text: 'Ledger'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _InfoTab(cs: cs, tt: tt),
            _AttendanceTab(cs: cs, tt: tt),
            _LedgerTab(cs: cs, tt: tt),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Settle Account'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {},
                  child: const Text('Payslip PDF'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);
  @override
  Widget build(BuildContext context, _, __) => Material(
    color: Theme.of(context).colorScheme.surface,
    child: tabBar,
  );
  @override
  double get maxExtent => 48;
  @override
  double get minExtent => 48;
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
      padding: const EdgeInsets.all(16),
      children: [
        _InfoCard(cs: cs, icon: Icons.badge_outlined, title: 'Employee Details',
          children: [
            _InfoRow(label: 'Employee ID', value: 'EMP-042'),
            _InfoRow(label: 'Department', value: 'Production'),
            _InfoRow(label: 'Role', value: 'Operator'),
            _InfoRow(label: 'Joined', value: '12 Mar 2023'),
          ],
        ),
        const SizedBox(height: 16),
        _InfoCard(cs: cs, icon: Icons.monetization_on_outlined, title: 'Wage Configuration',
          children: [
            _InfoRow(label: 'Wage Type', value: 'Daily'),
            _InfoRow(label: 'Rate', value: '₹450/day'),
            _InfoRow(label: 'OT Rate', value: '₹85/hr'),
            _InfoRow(label: 'Bank Account', value: 'XXXX-XXXX-4821'),
          ],
        ),
        const SizedBox(height: 16),
        _InfoCard(cs: cs, icon: Icons.contact_phone_outlined, title: 'Contact',
          children: [
            _InfoRow(label: 'Phone', value: '+91 98765 43210'),
            _InfoRow(label: 'Emergency', value: '+91 98765 43211'),
            _InfoRow(label: 'Address', value: 'Sector 12, Industrial Area'),
          ],
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final ColorScheme cs;
  final IconData icon;
  final String title;
  final List<Widget> children;
  const _InfoCard({
    required this.cs,
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            )),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
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
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _AttStat(label: 'Present', value: '22', color: cs.primary),
                    _AttStat(label: 'Absent', value: '2', color: cs.error),
                    _AttStat(label: 'Half-Day', value: '1', color: cs.tertiary),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: 22 / 26,
                  backgroundColor: cs.surfaceContainerHigh,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text('88% attendance this month',
                  style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(10, (i) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: i < 8 ? cs.primaryContainer : cs.errorContainer,
            child: Icon(
              i < 8 ? Icons.check : Icons.close,
              size: 16,
              color: i < 8 ? cs.onPrimaryContainer : cs.onErrorContainer,
            ),
          ),
          title: Text('${24 - i} Oct 2026', style: tt.bodyMedium),
          trailing: Text(i < 8 ? 'Present' : 'Absent',
            style: TextStyle(
              color: i < 8 ? cs.primary : cs.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        )),
      ],
    );
  }
}

class _AttStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _AttStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold, color: color,
        )),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
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
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: cs.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: _LedgerStat(
                  label: 'Total Jama', value: '₹32,500',
                  color: cs.onPrimaryContainer,
                )),
                Container(width: 1, height: 30,
                  color: cs.onPrimaryContainer.withValues(alpha: 0.2),
                ),
                Expanded(child: _LedgerStat(
                  label: 'Total Udhaar', value: '₹5,200',
                  color: cs.error,
                )),
                Container(width: 1, height: 30,
                  color: cs.onPrimaryContainer.withValues(alpha: 0.2),
                ),
                Expanded(child: _LedgerStat(
                  label: 'Net', value: '₹27,300',
                  color: cs.onPrimaryContainer,
                )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(6, (i) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: CircleAvatar(
            backgroundColor: cs.surfaceContainerHigh,
            child: Icon(
              i.isEven ? Icons.arrow_upward : Icons.arrow_downward,
              size: 18,
              color: i.isEven ? cs.primary : cs.error,
            ),
          ),
          title: Text(i.isEven ? 'Wage payment' : 'Advance taken',
              style: tt.bodyMedium),
          subtitle: Text('${24 - i} Oct 2026', style: tt.bodySmall),
          trailing: Text(
            i.isEven ? '+₹${450 + i * 50}' : '-₹${200 + i * 100}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: i.isEven ? cs.primary : cs.error,
            ),
          ),
        )),
      ],
    );
  }
}

class _LedgerStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _LedgerStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(
          fontWeight: FontWeight.bold, color: color, fontSize: 15,
        )),
        Text(label, style: TextStyle(
          fontSize: 11, color: color.withValues(alpha: 0.7),
        )),
      ],
    );
  }
}
