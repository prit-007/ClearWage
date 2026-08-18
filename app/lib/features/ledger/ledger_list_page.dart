import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/ledger_model.dart';
import '../../core/providers/services.dart';
import '../../data/services/dispute_service.dart';
import 'providers/ledger_providers.dart';
import '../../core/helpers.dart';
import '../disputes/raise_dispute_dialog.dart';
import '../../core/widgets/fluid_slide_in.dart';
import '../../core/widgets/employee_avatar.dart';

const int _pageSize = 20;

class LedgerListScreen extends ConsumerStatefulWidget {
  const LedgerListScreen({super.key});
  @override
  ConsumerState<LedgerListScreen> createState() => _LedgerListScreenState();
}

class _LedgerListScreenState extends ConsumerState<LedgerListScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  List<LedgerEntry> _entries = [];
  LedgerSummary? _summary;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  bool _listenerRegistered = false;
  late DateTime _startDate;
  late DateTime _endDate;

  String get _startStr =>
      '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}';
  String get _endStr =>
      '${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;
    _scrollCtrl.addListener(_onScroll);
    _fetch();
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
      _entries = [];
      _hasMore = true;
    });
    try {
      final svc = ref.read(ledgerServiceProvider);
      final entries = await svc.listByTenant(
        startDate: _startStr,
        endDate: _endStr,
        limit: _pageSize,
        offset: 0,
      );
      LedgerSummary? summary;
      try {
        summary = await svc.getSummary(startDate: _startStr, endDate: _endStr);
      } catch (_) {
        summary = null;
      }
      if (mounted) {
        setState(() {
          _entries = entries;
          _summary = summary;
          _hasMore = entries.length >= _pageSize;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final svc = ref.read(ledgerServiceProvider);
      final entries = await svc.listByTenant(
        startDate: _startStr,
        endDate: _endStr,
        limit: _pageSize,
        offset: _entries.length,
      );
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

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final start = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2024),
      lastDate: now,
    );
    if (start == null || !mounted) return;
    final end = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: start,
      lastDate: now,
    );
    if (end == null || !mounted) return;
    setState(() {
      _startDate = start;
      _endDate = end;
    });
    unawaited(_fetch());
  }

  @override
  Widget build(BuildContext context) {
    if (!_listenerRegistered) {
      _listenerRegistered = true;
      ref.listen(ledgerRefreshProvider, (_, _) => _fetch());
    }
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
                title: Text(
                  'Ledger Hub',
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                centerTitle: true,
                actions: const [],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: InkWell(
                    onTap: _pickDateRange,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            PhosphorIconsFill.calendarBlank,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              '${formatDate(_startDate)} to ${formatDate(_endDate)}',
                              style: tt.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            PhosphorIconsRegular.caretDown,
                            color: cs.onSurfaceVariant,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIconsFill.warningCircle,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load entries',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
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
                SliverToBoxAdapter(child: _buildSummary(cs, tt)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Text(
                      'Recent Transactions',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              PhosphorIconsFill.notebook,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No ledger entries yet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Entries will appear here once transactions are recorded.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: FluidSlideIn(
                          delay: (index * 50).clamp(0, 500),
                          child: _LedgerRow(
                            cs: cs,
                            tt: tt,
                            entry: _entries[index],
                            disputeService: ref.watch(disputeServiceProvider),
                          ),
                        ),
                      );
                    }, childCount: _entries.length),
                  ),
                if (_loadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'ledger_list_fab',
        onPressed: () => context.push('/new_ledger'),
        backgroundColor: cs.primary,
        icon: Icon(PhosphorIconsBold.plus, color: cs.onPrimary),
        label: Text(
          'New Entry',
          style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSummary(ColorScheme cs, TextTheme tt) {
    double jama = 0, udhaar = 0;
    if (_summary != null) {
      jama = _summary!.jamaTotal;
      udhaar = _summary!.udhaarTotal;
    } else {
      for (final e in _entries) {
        if (e.isJama) {
          jama += e.amount;
        } else {
          udhaar += e.amount;
        }
      }
    }
    final net = _summary != null ? _summary!.netBalance : jama - udhaar;
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
                  Text(
                    'Net Balance (MTD)',
                    style: tt.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${isPositive ? '+' : '-'}\u20B9${net.abs().toStringAsFixed(0)}',
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
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _LedgerRow extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final LedgerEntry entry;
  final DisputeService disputeService;
  const _LedgerRow({
    required this.cs,
    required this.tt,
    required this.entry,
    required this.disputeService,
  });

  @override
  Widget build(BuildContext context) {
    final isJama = entry.isJama;
    final amtColor = isJama ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return GestureDetector(
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Raise Dispute'),
                  onTap: () {
                    Navigator.pop(ctx);
                    showRaiseDisputeDialog(
                      context,
                      disputeService: disputeService,
                      ledgerId: entry.id,
                      employeeId: entry.employeeId,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: EmployeeAvatar(
            name: entry.employeeName,
            photoUrl: entry.employeePhoto,
            radius: 22,
          ),
          title: Text(
            entry.employeeName,
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Row(
            children: [
              Icon(
                PhosphorIconsRegular.calendarBlank,
                size: 12,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                formatDate(entry.date),
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isJama ? '+' : '-'}\u20B9${entry.amount.toStringAsFixed(0)}',
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: amtColor,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: amtColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isJama ? 'Jama' : 'Udhaar',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: amtColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
