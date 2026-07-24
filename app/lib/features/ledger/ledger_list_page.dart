import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LedgerListScreen extends StatelessWidget {
  const LedgerListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Ledger')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        children: [
          Card(
            color: cs.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(child: _SummaryColumn(
                    cs: cs, tt: tt,
                    label: 'Total Jama',
                    value: '₹1,24,500',
                    color: cs.primary,
                  )),
                  Container(width: 1, height: 40,
                    color: cs.onPrimaryContainer.withValues(alpha: 0.2),
                  ),
                  Expanded(child: _SummaryColumn(
                    cs: cs, tt: tt,
                    label: 'Total Udhaar',
                    value: '₹42,800',
                    color: cs.error,
                  )),
                  Container(width: 1, height: 40,
                    color: cs.onPrimaryContainer.withValues(alpha: 0.2),
                  ),
                  Expanded(child: _SummaryColumn(
                    cs: cs, tt: tt,
                    label: 'Net Balance',
                    value: '₹81,700',
                    color: cs.onPrimaryContainer,
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _LedgerGroup(cs: cs, tt: tt, header: 'Today, 24 Oct', entries: [
            _LedgerEntry(name: 'Rahul Sharma', note: 'Wage payment', amount: '+₹500',
                isJama: true, initials: 'RS'),
            _LedgerEntry(name: 'Sunita Devi', note: 'Advance taken', amount: '-₹200',
                isJama: false, initials: 'SD'),
            _LedgerEntry(name: 'Vijay Kumar', note: 'Settlement', amount: '+₹1,200',
                isJama: true, initials: 'VK'),
          ]),
          const SizedBox(height: 16),
          _LedgerGroup(cs: cs, tt: tt, header: '23 Oct 2026', entries: [
            _LedgerEntry(name: 'Amit Singh', note: 'Wage payment', amount: '+₹450',
                isJama: true, initials: 'AS'),
            _LedgerEntry(name: 'Priya Patel', note: 'Udhaar repayment', amount: '+₹300',
                isJama: true, initials: 'PP'),
            _LedgerEntry(name: 'Ravi Verma', note: 'Advance taken', amount: '-₹500',
                isJama: false, initials: 'RV'),
            _LedgerEntry(name: 'Anita Gupta', note: 'Wage payment', amount: '+₹380',
                isJama: true, initials: 'AG'),
          ]),
          const SizedBox(height: 16),
          _LedgerGroup(cs: cs, tt: tt, header: '22 Oct 2026', entries: [
            _LedgerEntry(name: 'Suresh Rao', note: 'Advance taken', amount: '-₹150',
                isJama: false, initials: 'SR'),
            _LedgerEntry(name: 'Deepa Joshi', note: 'Wage payment', amount: '+₹520',
                isJama: true, initials: 'DJ'),
          ]),
        ],
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () {},
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add),
            SizedBox(width: 8),
            Text('New Entry'),
          ],
        ),
      ),
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final String label, value;
  final Color color;
  const _SummaryColumn({
    required this.cs, required this.tt,
    required this.label, required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: tt.labelSmall?.copyWith(
          color: cs.onPrimaryContainer.withValues(alpha: 0.7),
        )),
        const SizedBox(height: 4),
        Text(value, style: tt.titleMedium?.copyWith(
          color: color, fontWeight: FontWeight.bold,
        )),
      ],
    );
  }
}

class _LedgerGroup extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final String header;
  final List<_LedgerEntry> entries;
  const _LedgerGroup({
    required this.cs, required this.tt,
    required this.header, required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(header, style: tt.titleSmall?.copyWith(
          color: cs.onSurface.withValues(alpha: 0.6),
        )),
        const SizedBox(height: 8),
        ...entries,
      ],
    );
  }
}

class _LedgerEntry extends StatelessWidget {
  final String name, note, amount, initials;
  final bool isJama;
  const _LedgerEntry({
    required this.name, required this.note,
    required this.amount, required this.isJama,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final chipColor = isJama ? cs.primary : cs.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: CircleAvatar(
          backgroundColor: cs.surfaceContainerHigh,
          child: Text(initials, style: TextStyle(
            fontWeight: FontWeight.w600, color: cs.onSurface,
          )),
        ),
        title: Text(name, style: tt.bodyMedium),
        subtitle: Text(note, style: tt.bodySmall),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(amount, style: tt.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: isJama ? cs.primary : cs.error,
            )),
            const SizedBox(height: 2),
            Chip(
              label: Text(isJama ? 'Jama' : 'Udhaar',
                style: TextStyle(fontSize: 10, color: chipColor),
              ),
              backgroundColor: chipColor.withValues(alpha: 0.12),
              side: BorderSide.none,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ],
        ),
      ),
    );
  }
}
