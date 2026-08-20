import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../data/models/shift_model.dart';
import '../../core/providers/services.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/widgets/fluid_slide_in.dart';
import '../../core/helpers.dart';
import '../../core/design_tokens.dart';
import '../../core/responsive.dart';

const int _pageSize = 20;

class MyShiftsPage extends ConsumerStatefulWidget {
  const MyShiftsPage({super.key});
  @override
  ConsumerState<MyShiftsPage> createState() => _MyShiftsPageState();
}

class _MyShiftsPageState extends ConsumerState<MyShiftsPage> {
  final ScrollController _scrollCtrl = ScrollController();
  List<Shift> _items = [];
  bool _loading = false;
  bool _hasMore = true;
  int _page = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
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
        !_loading &&
        _hasMore) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final items = await ref
          .read(shiftServiceProvider)
          .list(limit: _pageSize, offset: _page * _pageSize);
      if (mounted) {
        setState(() {
          _items.addAll(items);
          _page++;
          _hasMore = items.length >= _pageSize;
          _loading = false;
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = err.toString();
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    unawaited(HapticFeedback.mediumImpact());
    setState(() {
      _items = [];
      _page = 0;
      _hasMore = true;
      _error = null;
    });
    await _fetch();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: RefreshIndicator(
          color: cs.primary,
          backgroundColor: cs.surface,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollCtrl,
            physics: AppScrollPhysics.physics(
              parent: const AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverAppBar(
                backgroundColor: cs.surface.withValues(alpha: 0.95),
                pinned: true,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(
                    PhosphorIconsRegular.arrowLeft,
                    color: cs.onSurface,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Shift Timings',
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                centerTitle: true,
              ),
              if (_error != null)
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
                          'Failed to load shifts',
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
                          onPressed: _onRefresh,
                        ),
                      ],
                    ),
                  ),
                )
              else if (_loading && _items.isEmpty)
                const ShimmerLoading(itemCount: 3, height: 120)
              else if (_items.isEmpty)
                const SliverFillRemaining(
                  child: EmptyState(
                    icon: PhosphorIconsRegular.clock,
                    title: 'No shifts configured',
                    subtitle: 'No shift timings available.',
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final shift = _items[index];
                      return FluidSlideIn(
                        delay: index * 100,
                        child: _ReadOnlyShiftCard(cs: cs, tt: tt, shift: shift),
                      );
                    }, childCount: _items.length),
                  ),
                ),
                if (_loading)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyShiftCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final Shift shift;

  const _ReadOnlyShiftCard({
    required this.cs,
    required this.tt,
    required this.shift,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: shift.isDefault
                    ? cs.primary.withValues(alpha: 0.1)
                    : cs.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: PhosphorIcon(
                shift.crossesMidnight
                    ? PhosphorIconsDuotone.moonStars
                    : PhosphorIconsDuotone.sun,
                color: shift.isDefault ? cs.primary : cs.onSurfaceVariant,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          shift.name,
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      if (shift.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'DEFAULT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: cs.onPrimaryContainer,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                      if (shift.crossesMidnight) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'MIDNIGHT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.purple,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${formatTime(shift.startTime)} \u2014 ${formatTime(shift.endTime)}',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Grace: ${shift.gracePeriodMinutes} mins',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
