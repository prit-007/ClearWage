import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:intl/intl.dart';
import '../../data/models/holiday_model.dart';
import '../../core/providers/services.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/fluid_slide_in.dart';
import '../../core/responsive.dart';

const int _pageSize = 20;

class MyHolidaysPage extends ConsumerStatefulWidget {
  const MyHolidaysPage({super.key});
  @override
  ConsumerState<MyHolidaysPage> createState() => _MyHolidaysPageState();
}

class _MyHolidaysPageState extends ConsumerState<MyHolidaysPage> {
  final ScrollController _scrollCtrl = ScrollController();
  List<Holiday> _items = [];
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
          .read(holidayServiceProvider)
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
                  'Holidays',
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
                          'Failed to load holidays',
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
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_items.isEmpty)
                const SliverFillRemaining(
                  child: EmptyState(
                    icon: PhosphorIconsRegular.calendarStar,
                    title: 'No holidays configured',
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final h = _items[index];
                      return FluidSlideIn(
                        delay: index * 80,
                        child: _ReadOnlyHolidayCard(cs: cs, tt: tt, holiday: h),
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

class _ReadOnlyHolidayCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final Holiday holiday;

  const _ReadOnlyHolidayCard({
    required this.cs,
    required this.tt,
    required this.holiday,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(holiday.date) ?? DateTime.now();
    final day = DateFormat('dd').format(date);
    final month = DateFormat('MMM').format(date).toUpperCase();

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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cs.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    month,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: cs.tertiary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    day,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: cs.tertiary,
                      letterSpacing: -1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    holiday.name,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (holiday.isRecurring)
                    Row(
                      children: [
                        Icon(
                          PhosphorIconsRegular.arrowClockwise,
                          size: 14,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Recurring',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
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
