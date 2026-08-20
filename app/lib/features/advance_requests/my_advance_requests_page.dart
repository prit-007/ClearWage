import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:intl/intl.dart';
import '../../data/models/advance_request_model.dart';
import '../../core/providers/services.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/fluid_slide_in.dart';
import '../../core/design_tokens.dart';
import '../../core/responsive.dart';

const int _pageSize = 20;

class MyAdvanceRequestsPage extends ConsumerStatefulWidget {
  const MyAdvanceRequestsPage({super.key});
  @override
  ConsumerState<MyAdvanceRequestsPage> createState() =>
      _MyAdvanceRequestsPageState();
}

class _MyAdvanceRequestsPageState extends ConsumerState<MyAdvanceRequestsPage> {
  final ScrollController _scrollCtrl = ScrollController();
  List<AdvanceRequest> _requests = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
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
        !_loadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
      _requests = [];
      _hasMore = true;
    });
    try {
      final svc = ref.read(advanceRequestServiceProvider);
      final requests = await svc.list(limit: _pageSize, offset: 0);
      if (mounted) {
        setState(() {
          _requests = requests;
          _hasMore = requests.length >= _pageSize;
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
      final svc = ref.read(advanceRequestServiceProvider);
      final requests = await svc.list(
        limit: _pageSize,
        offset: _requests.length,
      );
      if (mounted) {
        setState(() {
          _requests.addAll(requests);
          _hasMore = requests.length >= _pageSize;
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
          color: cs.primary,
          backgroundColor: cs.surface,
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
                  'My Advance Requests',
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                centerTitle: true,
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
                          'Failed to load requests',
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
              else if (_requests.isEmpty)
                const SliverFillRemaining(
                  child: EmptyState(
                    icon: PhosphorIconsRegular.handCoins,
                    title: 'No advance requests',
                    subtitle: 'Your advance requests will appear here.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final req = _requests[index];
                      return FluidSlideIn(
                        delay: index * 80,
                        child: _AdvanceRequestCard(
                          cs: cs,
                          tt: tt,
                          request: req,
                        ),
                      );
                    }, childCount: _requests.length),
                  ),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _AdvanceRequestCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final AdvanceRequest request;

  const _AdvanceRequestCard({
    required this.cs,
    required this.tt,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = request.isPending;
    final statusColor = isPending
        ? AppColors.warning
        : request.isApproved
        ? AppColors.success
        : AppColors.danger;
    final statusLabel = isPending
        ? 'Pending'
        : request.isApproved
        ? 'Approved'
        : 'Denied';

    final date = DateTime.tryParse(request.createdAt);
    final dateStr = date != null ? DateFormat('dd MMM yyyy').format(date) : '';

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPending
                            ? PhosphorIconsFill.clockUser
                            : PhosphorIconsFill.checkCircle,
                        color: statusColor,
                        size: 12,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\u20B9${request.amount.toStringAsFixed(0)}',
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.primary,
                    letterSpacing: -1.0,
                  ),
                ),
              ],
            ),
            if (dateStr.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    PhosphorIconsRegular.calendarBlank,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateStr,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            if (request.note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIconsRegular.quotes,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.note,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
