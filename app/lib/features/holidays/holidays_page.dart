import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/validated_field.dart';
import '../../models/holiday_model.dart';
import '../../providers/providers.dart';
import '../../core/widgets/fluid_slide_in.dart';
import '../../core/helpers.dart';

const int _pageSize = 20;

class HolidaysScreen extends ConsumerStatefulWidget {
  const HolidaysScreen({super.key});
  @override
  ConsumerState<HolidaysScreen> createState() => _HolidaysScreenState();
}

class _HolidaysScreenState extends ConsumerState<HolidaysScreen> {
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
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 && !_loading && _hasMore) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final items = await ref.read(holidayServiceProvider).list(limit: _pageSize, offset: _page * _pageSize);
      if (mounted) {
        setState(() {
          _items.addAll(items);
          _page++;
          _hasMore = items.length >= _pageSize;
          _loading = false;
        });
      }
    } catch (err) {
      if (mounted) setState(() { _loading = false; _error = err.toString(); });
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _items = [];
      _page = 0;
      _hasMore = true;
      _error = null;
    });
    await _fetch();
  }

  Future<void> _showHolidaySheet() async {
    HapticFeedback.mediumImpact();
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _HolidayFormSheet(),
    );
    if (result != null) {
      try {
        await ref.read(holidayServiceProvider).create(result);
        if (mounted) _onRefresh();
      } catch (e) {
        if (mounted) showError(context, e);
      }
    }
  }

  Future<void> _deleteHoliday(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Holiday'),
        content: const Text('Are you sure you want to delete this holiday?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error))),
        ],
      ),
    );
    if (confirmed != true) return;
    HapticFeedback.heavyImpact();
    try {
      await ref.read(holidayServiceProvider).delete(id);
      if (mounted) _onRefresh();
    } catch (e) {
      if (mounted) showError(context, e);
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
          color: cs.primary,
          backgroundColor: cs.surface,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverAppBar(
                backgroundColor: cs.surface.withValues(alpha: 0.95),
                pinned: true,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(PhosphorIconsRegular.arrowLeft, color: cs.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text('Holidays', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: Icon(PhosphorIconsBold.plus, color: cs.primary),
                    onPressed: _showHolidaySheet,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              if (_error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIconsFill.warningCircle, size: 48, color: Theme.of(context).colorScheme.error),
                        const SizedBox(height: 16),
                        Text('Failed to load holidays', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(_error!, style: Theme.of(context).textTheme.bodySmall),
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
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              else if (_items.isEmpty)
                SliverFillRemaining(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PhosphorIcon(PhosphorIconsDuotone.calendarStar, size: 72, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                      const SizedBox(height: 24),
                      Text('No holidays configured', style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
                    ],
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final h = _items[index];
                        return FluidSlideIn(
                          delay: index * 80,
                          child: _PremiumHolidayCard(cs: cs, tt: tt, holiday: h, onDelete: () => _deleteHoliday(h.id)),
                        );
                      },
                      childCount: _items.length,
                    ),
                  ),
                ),
                if (_loading)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary)),
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

class _PremiumHolidayCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final Holiday holiday;
  final VoidCallback onDelete;

  const _PremiumHolidayCard({required this.cs, required this.tt, required this.holiday, required this.onDelete});

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
        boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
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
                  Text(month, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: cs.tertiary, letterSpacing: 1.0)),
                  Text(day, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: cs.tertiary, letterSpacing: -1.0)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(holiday.name, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  if (holiday.isRecurring)
                    Row(
                      children: [
                        Icon(PhosphorIconsRegular.arrowsClockwise, size: 14, color: cs.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text('Repeats Annually', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                      ],
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(PhosphorIconsRegular.trash, color: cs.error.withValues(alpha: 0.7)),
              onPressed: () {
                HapticFeedback.lightImpact();
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HolidayFormSheet extends StatefulWidget {
  const _HolidayFormSheet();
  @override
  State<_HolidayFormSheet> createState() => _HolidayFormSheetState();
}

class _HolidayFormSheetState extends State<_HolidayFormSheet> {
  final _nameCtrl = TextEditingController();
  DateTime? _selectedDate;
  bool _recurring = false;
  String? _dateError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;
    if (_nameCtrl.text.trim().isEmpty) valid = false;
    if (_selectedDate == null) {
      setState(() => _dateError = 'Select a date');
      valid = false;
    } else {
      setState(() => _dateError = null);
    }
    setState(() {});
    return valid;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: sheetHandle(cs)),
              const SizedBox(height: 24),
              Text('Mark Factory Holiday', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 32),

              ValidatedField(
                controller: _nameCtrl,
                label: 'Holiday Name',
                prefixIcon: PhosphorIconsRegular.sparkle,
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter holiday name' : null,
              ),
              const SizedBox(height: 24),

              Text('Date', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: cs.onSurfaceVariant)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  HapticFeedback.selectionClick();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2023),
                    lastDate: DateTime(2028),
                  );
                  if (picked != null) setState(() { _selectedDate = picked; _dateError = null; });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _dateError != null ? cs.error.withValues(alpha: 0.5) : Colors.transparent, width: 2),
                  ),
                  child: Row(
                    children: [
                      Icon(PhosphorIconsRegular.calendarBlank, color: _dateError != null ? cs.error : cs.onSurfaceVariant),
                      const SizedBox(width: 16),
                      Text(
                        _selectedDate == null ? 'Select Date' : DateFormat('dd MMM yyyy').format(_selectedDate!),
                        style: TextStyle(fontWeight: FontWeight.w700, color: _selectedDate == null ? cs.onSurfaceVariant : cs.onSurface, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              if (_dateError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, size: 14, color: cs.error),
                      const SizedBox(width: 6),
                      Text(_dateError!, style: tt.bodySmall?.copyWith(color: cs.error, fontWeight: FontWeight.w600, fontSize: 12)),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Repeats Annually', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      Text('Automatically mark this every year', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                  Switch.adaptive(
                    value: _recurring,
                    activeTrackColor: cs.primary,
                    onChanged: (v) { HapticFeedback.lightImpact(); setState(() => _recurring = v); },
                  ),
                ],
              ),
              const SizedBox(height: 32),

              FilledButton(
                onPressed: () {
                  if (!_validate()) return;
                  HapticFeedback.heavyImpact();
                  Navigator.pop(context, {
                    'name': _nameCtrl.text.trim(),
                    'date': '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                    'is_recurring': _recurring,
                  });
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Add Holiday', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
