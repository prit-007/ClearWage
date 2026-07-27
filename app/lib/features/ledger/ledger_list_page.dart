import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../models/ledger_model.dart';
import '../../providers/providers.dart';
import '../../core/widgets/fluid_slide_in.dart';

const int _pageSize = 20;

class LedgerListScreen extends ConsumerStatefulWidget {
  const LedgerListScreen({super.key});
  @override
  ConsumerState<LedgerListScreen> createState() => _LedgerListScreenState();
}

class _LedgerListScreenState extends ConsumerState<LedgerListScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  List<LedgerEntry> _entries = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;

  String get _startDate {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
  }

  String get _endDate {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _fetch();
    ref.listen(ledgerRefreshProvider, (_, _) => _fetch());
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 && !_loadingMore && _hasMore) {
      _loadMore();
    }
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; _entries = []; _hasMore = true; });
    try {
      final svc = ref.read(ledgerServiceProvider);
      final entries = await svc.listByTenant(startDate: _startDate, endDate: _endDate, limit: _pageSize, offset: 0);
      if (mounted) {
        setState(() {
          _entries = entries;
          _hasMore = entries.length >= _pageSize;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final svc = ref.read(ledgerServiceProvider);
      final entries = await svc.listByTenant(startDate: _startDate, endDate: _endDate, limit: _pageSize, offset: _entries.length);
      if (mounted) {
        setState(() {
          _entries.addAll(entries);
          _hasMore = entries.length >= _pageSize;
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetch,
          child: CustomScrollView(
            controller: _scrollCtrl,
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
                title: Text('Ledger Hub', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                centerTitle: true,
                actions: const [],
              ),
              if (_loading)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              else if (_error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIconsFill.warningCircle, size: 48, color: Theme.of(context).colorScheme.error),
                        const SizedBox(height: 16),
                        Text('Failed to load entries', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(_error!, style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          icon: const Icon(PhosphorIconsFill.arrowClockwise),
                          label: const Text('Retry'),
                          onPressed: _fetch,
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: _buildSummary(cs, tt),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text('Recent Transactions', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                ),
                if (_entries.isEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 48),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(PhosphorIconsFill.notebook, size: 48, color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(height: 24),
                          Text('No ledger entries yet', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text('Entries will appear here once transactions are recorded.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: FluidSlideIn(
                            delay: (index * 50).clamp(0, 500),
                            child: _LedgerRow(cs: cs, tt: tt, entry: _entries[index]),
                          ),
                        );
                      },
                      childCount: _entries.length,
                    ),
                  ),
                if (_loadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/new_ledger'),
        backgroundColor: cs.primary,
        icon: Icon(PhosphorIconsBold.plus, color: cs.onPrimary),
        label: Text('New Entry', style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSummary(ColorScheme cs, TextTheme tt) {
    double jama = 0, udhaar = 0;
    for (final e in _entries) {
      if (e.isJama) { jama += e.amount; } else { udhaar += e.amount; }
    }
    final net = jama - udhaar;
    final isPositive = net >= 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: FluidSlideIn(
        delay: 0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cs.primary.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  Text('Net Balance (MTD)', style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    '${isPositive ? '+' : '-'}\u20B9${net.abs().toStringAsFixed(0)}',
                    style: tt.displayMedium?.copyWith(
                      color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
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
                          value: '\u20B9${jama.toStringAsFixed(0)}',
                          icon: PhosphorIconsFill.arrowUpRight,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      Container(width: 1, height: 40, color: cs.outlineVariant),
                      Expanded(
                        child: _SummaryStat(
                          label: 'Total Udhaar',
                          value: '\u20B9${udhaar.toStringAsFixed(0)}',
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
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _SummaryStat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _LedgerRow extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final LedgerEntry entry;
  const _LedgerRow({required this.cs, required this.tt, required this.entry});

  @override
  Widget build(BuildContext context) {
    final isJama = entry.isJama;
    final amtColor = isJama ? const Color(0xFF10B981) : const Color(0xFFEF4444);
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
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          child: Text(initials, style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface, fontSize: 13)),
        ),
        title: Text(entry.employeeName, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        subtitle: Row(
          children: [
            Icon(PhosphorIconsRegular.calendarBlank, size: 12, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(entry.date, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${isJama ? '+' : '-'}\u20B9${entry.amount.toStringAsFixed(0)}',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: amtColor)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: amtColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(isJama ? 'Jama' : 'Udhaar', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: amtColor)),
            ),
          ],
        ),
      ),
    );
  }
}
