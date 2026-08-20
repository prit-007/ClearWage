import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../data/models/advance_request_model.dart';
import '../../core/providers/services.dart';
import '../dashboard/providers/dashboard_providers.dart';
import '../ledger/providers/ledger_providers.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/fluid_slide_in.dart';
import '../../core/widgets/employee_avatar.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/helpers.dart';
import '../../core/design_tokens.dart';
import '../../core/responsive.dart';
import 'dart:async';

const int _pageSize = 20;

class AdvanceRequestsScreen extends ConsumerStatefulWidget {
  const AdvanceRequestsScreen({super.key});
  @override
  ConsumerState<AdvanceRequestsScreen> createState() =>
      _AdvanceRequestsScreenState();
}

class _AdvanceRequestsScreenState extends ConsumerState<AdvanceRequestsScreen> {
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

  Future<void> _handleActionSheet(AdvanceRequest req) async {
    if (!req.isPending) return;
    unawaited(HapticFeedback.mediumImpact());

    final action = await showAdaptiveSheet<String>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final tt = Theme.of(ctx).textTheme;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            child: _AdvanceActionSheetContent(
              cs: cs,
              tt: tt,
              req: req,
              ref: ref,
            ),
          ),
        );
      },
    );

    if (action == 'approved' || action == 'denied') {
      await _fetch();
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
            physics: AppScrollPhysics.physics(),
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
                  'Jama Requests',
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                centerTitle: true,
              ),
              if (_loading)
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(24, 8, 24, 40),
                  sliver: ShimmerLoading(itemCount: 4, height: 100),
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
                    title: 'No pending requests',
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
                          onAction: () => _handleActionSheet(req),
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

class _AdvanceActionSheetContent extends ConsumerStatefulWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final AdvanceRequest req;
  final WidgetRef ref;

  const _AdvanceActionSheetContent({
    required this.cs,
    required this.tt,
    required this.req,
    required this.ref,
  });

  @override
  ConsumerState<_AdvanceActionSheetContent> createState() =>
      _AdvanceActionSheetContentState();
}

class _AdvanceActionSheetContentState
    extends ConsumerState<_AdvanceActionSheetContent> {
  bool _loading = false;
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _approve() async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Approve Advance',
      message: 'Approve this advance request?',
      confirmLabel: 'Approve',
      icon: PhosphorIconsRegular.checkCircle,
    );
    if (confirm != true) return;
    setState(() => _loading = true);
    try {
      unawaited(HapticFeedback.heavyImpact());
      final now = DateTime.now();
      final date =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await widget.ref
          .read(advanceRequestServiceProvider)
          .approve(widget.req.id, date: date);
      widget.ref.invalidate(dashboardDataProvider);
      widget.ref.read(ledgerRefreshProvider.notifier).state++;
      if (mounted) Navigator.pop(context, 'approved');
    } catch (e) {
      if (mounted) showError(context, e);
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deny() async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Deny Advance',
      message: 'Deny this advance request?',
      confirmLabel: 'Deny',
      icon: PhosphorIconsRegular.xCircle,
      isDestructive: true,
    );
    if (confirm != true) return;
    setState(() => _loading = true);
    try {
      unawaited(HapticFeedback.selectionClick());
      await widget.ref
          .read(advanceRequestServiceProvider)
          .deny(widget.req.id, reason: _reasonCtrl.text);
      widget.ref.invalidate(dashboardDataProvider);
      widget.ref.read(ledgerRefreshProvider.notifier).state++;
      if (mounted) Navigator.pop(context, 'denied');
    } catch (e) {
      if (mounted) showError(context, e);
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final tt = widget.tt;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        sheetHandle(cs),
        const SizedBox(height: 24),
        CircleAvatar(
          radius: 32,
          backgroundColor: cs.primaryContainer,
          child: PhosphorIcon(
            PhosphorIconsDuotone.handCoins,
            size: 32,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.req.employeeName,
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          'Requests an advance of \u20B9${widget.req.amount.toStringAsFixed(0)}',
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(PhosphorIconsRegular.quotes, color: cs.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.req.note,
                  style: tt.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _reasonCtrl,
          decoration: InputDecoration(
            hintText: 'Reason (optional)',
            hintStyle: TextStyle(color: cs.onSurfaceVariant),
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 24),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: CircularProgressIndicator(),
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _deny,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: const BorderSide(color: AppColors.danger),
                  ),
                  child: const Text(
                    'Deny',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: _approve,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Approve',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _AdvanceRequestCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final AdvanceRequest request;
  final VoidCallback onAction;

  const _AdvanceRequestCard({
    required this.cs,
    required this.tt,
    required this.request,
    required this.onAction,
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
        ? 'Pending Action'
        : request.isApproved
        ? 'Approved'
        : 'Denied';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: isPending ? onAction : () => HapticFeedback.selectionClick(),
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    EmployeeAvatar(
                      name: request.employeeName,
                      photoUrl: request.employeePhoto,
                      radius: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.employeeName,
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            request.note,
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isPending)
                      Icon(
                        PhosphorIconsRegular.caretRight,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
