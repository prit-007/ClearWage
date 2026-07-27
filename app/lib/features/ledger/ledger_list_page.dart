import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../models/ledger_model.dart';
import '../../providers/providers.dart';
import '../../core/widgets/fluid_slide_in.dart';

final ledgerListProvider = FutureProvider.autoDispose<List<LedgerEntry>>((ref) {
  final now = DateTime.now();
  final start = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
  final end = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  return ref.watch(ledgerServiceProvider).listByTenant(startDate: start, endDate: end);
});

class LedgerListScreen extends ConsumerWidget {
  const LedgerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final async = ref.watch(ledgerListProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: cs.surface.withValues(alpha: 0.9),
              pinned: true,
              elevation: 0,
              leading: IconButton(
                icon: Icon(PhosphorIconsRegular.arrowLeft, color: cs.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text('Ledger Hub',
                  style: tt.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(PhosphorIconsRegular.funnel,
                      color: cs.onSurfaceVariant),
                  onPressed: () {},
                ),
              ],
            ),
            async.when(
              loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverFillRemaining(
                  child: Center(
                      child: Text('Error: $e',
                          style: TextStyle(color: cs.error)))),
              data: (entries) {
                double jama = 0, udhaar = 0;
                for (final e in entries) {
                  if (e.isJama) {
                    jama += e.amount;
                  } else {
                    udhaar += e.amount;
                  }
                }
                final net = jama - udhaar;

                return SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      child: FluidSlideIn(
                        delay: 0,
                        child: _GlassSummaryCard(
                            cs: cs,
                            tt: tt,
                            jama: jama,
                            udhaar: udhaar,
                            net: net),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      child: Text('Recent Transactions',
                          style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700)),
                    ),
                    if (entries.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(
                            child: Text('No ledger entries yet.')),
                      )
                    else
                      ...List.generate(entries.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24),
                          child: FluidSlideIn(
                            delay: (index * 50).clamp(0, 500),
                            child: _LedgerRow(
                                cs: cs,
                                tt: tt,
                                entry: entries[index]),
                          ),
                        );
                      }),
                    const SizedBox(height: 100),
                  ]),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, '/new_ledger'),
        backgroundColor: cs.primary,
        icon: Icon(PhosphorIconsBold.plus, color: cs.onPrimary),
        label: Text('New Entry',
            style:
                TextStyle(color: cs.onPrimary, fontWeight: FontWeight.bold)),
      ),
    );
  }
}



class _GlassSummaryCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final double jama, udhaar, net;

  const _GlassSummaryCard(
      {required this.cs,
      required this.tt,
      required this.jama,
      required this.udhaar,
      required this.net});

  @override
  Widget build(BuildContext context) {
    final isPositive = net >= 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: cs.primary.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Text('Net Balance (MTD)',
                  style: tt.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                '${isPositive ? '+' : '-'}₹${net.abs().toStringAsFixed(0)}',
                style: tt.displayMedium?.copyWith(
                  color: isPositive
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _SummaryStat(
                      label: 'Total Jama',
                      value: '₹${jama.toStringAsFixed(0)}',
                      icon: PhosphorIconsFill.arrowUpRight,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  Container(
                      width: 1,
                      height: 40,
                      color: cs.outlineVariant),
                  Expanded(
                    child: _SummaryStat(
                      label: 'Total Udhaar',
                      value: '₹${udhaar.toStringAsFixed(0)}',
                      icon: PhosphorIconsFill.arrowDownLeft,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _SummaryStat(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color)),
      ],
    );
  }
}

class _LedgerRow extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final LedgerEntry entry;

  const _LedgerRow(
      {required this.cs, required this.tt, required this.entry});

  @override
  Widget build(BuildContext context) {
    final isJama = entry.isJama;
    final amtColor =
        isJama ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final initials = entry.employeeName
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor:
              cs.surfaceContainerHighest.withValues(alpha: 0.5),
          child: Text(initials,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                  fontSize: 13)),
        ),
        title: Text(entry.employeeName,
            style: tt.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        subtitle: Row(
          children: [
            Icon(PhosphorIconsRegular.calendarBlank,
                size: 12, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(entry.date,
                style: tt.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
                '${isJama ? '+' : '-'}₹${entry.amount.toStringAsFixed(0)}',
                style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800, color: amtColor)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: amtColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(isJama ? 'Jama' : 'Udhaar',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: amtColor)),
            ),
          ],
        ),
      ),
    );
  }
}
