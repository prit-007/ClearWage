import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/ledger_model.dart';
import '../../providers/providers.dart';

final ledgerListProvider = FutureProvider.autoDispose<List<LedgerEntry>>((ref) {
  return ref.watch(ledgerServiceProvider).listByTenant();
});

class LedgerListScreen extends ConsumerWidget {
  const LedgerListScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final async = ref.watch(ledgerListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Ledger')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('$e', style: TextStyle(color: cs.error), textAlign: TextAlign.center),
          ),
        ),
        data: (entries) {
          double jama = 0, udhaar = 0;
          for (final e in entries) {
            if (e.isJama) jama += e.amount;
            else udhaar += e.amount;
          }
          final net = jama - udhaar;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Card(
                color: cs.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(child: _SummaryColumn(cs: cs, tt: tt,
                        label: 'Total Jama', value: '\u20B9${jama.toStringAsFixed(0)}',
                        color: cs.primary)),
                      Container(width: 1, height: 40,
                        color: cs.onPrimaryContainer.withValues(alpha: 0.2)),
                      Expanded(child: _SummaryColumn(cs: cs, tt: tt,
                        label: 'Total Udhaar', value: '\u20B9${udhaar.toStringAsFixed(0)}',
                        color: cs.error)),
                      Container(width: 1, height: 40,
                        color: cs.onPrimaryContainer.withValues(alpha: 0.2)),
                      Expanded(child: _SummaryColumn(cs: cs, tt: tt,
                        label: 'Net Balance', value: '\u20B9${net.toStringAsFixed(0)}',
                        color: cs.onPrimaryContainer)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Text('No ledger entries yet',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4))),
                )
              else
                ...entries.map((e) => _LedgerRow(cs: cs, tt: tt, entry: e)),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  final ColorScheme cs; final TextTheme tt;
  final String label, value; final Color color;
  const _SummaryColumn({required this.cs, required this.tt,
    required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label, style: tt.labelSmall?.copyWith(color: cs.onPrimaryContainer.withValues(alpha: 0.7))),
      const SizedBox(height: 4),
      Text(value, style: tt.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
    ]);
  }
}

class _LedgerRow extends StatelessWidget {
  final ColorScheme cs; final TextTheme tt;
  final LedgerEntry entry;
  const _LedgerRow({required this.cs, required this.tt, required this.entry});
  @override
  Widget build(BuildContext context) {
    final amtColor = entry.isJama ? cs.primary : cs.error;
    final initials = entry.employeeName.split(' ').map((e) => e[0]).take(2).join();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: CircleAvatar(
          backgroundColor: cs.surfaceContainerHigh,
          child: Text(initials, style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
        ),
        title: Text(entry.employeeName, style: tt.bodyMedium),
        subtitle: Text(entry.note ?? entry.date, style: tt.bodySmall),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${entry.isJama ? '+' : '-'}\u20B9${entry.amount.toStringAsFixed(0)}',
                style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: amtColor)),
            const SizedBox(height: 2),
            Chip(
              label: Text(entry.isJama ? 'Jama' : 'Udhaar',
                style: TextStyle(fontSize: 10, color: amtColor)),
              backgroundColor: amtColor.withValues(alpha: 0.12),
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
