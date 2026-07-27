import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../models/advance_request_model.dart';
import '../../providers/providers.dart';
import '../../core/widgets/fluid_slide_in.dart';
import '../../core/helpers.dart';

final advanceRequestsProvider = FutureProvider.autoDispose<List<AdvanceRequest>>((ref) {
  return ref.watch(advanceRequestServiceProvider).list();
});

class AdvanceRequestsScreen extends ConsumerWidget {
  const AdvanceRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final async = ref.watch(advanceRequestsProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: cs.surface.withValues(alpha: 0.95),
              pinned: true,
              elevation: 0,
              leading: IconButton(
                icon: Icon(PhosphorIconsRegular.arrowLeft, color: cs.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text('Jama Requests', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              centerTitle: true,
            ),
            async.when(
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverFillRemaining(child: Center(child: Text('$e', style: TextStyle(color: cs.error)))),
              data: (requests) => requests.isEmpty
                  ? SliverFillRemaining(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.3), shape: BoxShape.circle),
                            child: PhosphorIcon(PhosphorIconsDuotone.wallet, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                          ),
                          const SizedBox(height: 24),
                          Text('No pending requests', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final req = requests[index];
                            return FluidSlideIn(
                              delay: index * 80,
                              child: _AdvanceRequestCard(cs: cs, tt: tt, request: req, onAction: () => _handleActionSheet(context, ref, req)),
                            );
                          },
                          childCount: requests.length,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _handleActionSheet(BuildContext context, WidgetRef ref, AdvanceRequest req) async {
  if (!req.isPending) return;
  HapticFeedback.mediumImpact();

  final action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
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
          child: _AdvanceActionSheetContent(cs: cs, tt: tt, req: req, ref: ref),
        ),
      );
    },
  );

  if (action == 'approved' || action == 'denied') {
    ref.invalidate(advanceRequestsProvider);
  }
}

class _AdvanceActionSheetContent extends ConsumerStatefulWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final AdvanceRequest req;
  final WidgetRef ref;

  const _AdvanceActionSheetContent({required this.cs, required this.tt, required this.req, required this.ref});

  @override
  ConsumerState<_AdvanceActionSheetContent> createState() => _AdvanceActionSheetContentState();
}

class _AdvanceActionSheetContentState extends ConsumerState<_AdvanceActionSheetContent> {
  bool _loading = false;

  Future<void> _approve() async {
    setState(() => _loading = true);
    try {
      HapticFeedback.heavyImpact();
      final now = DateTime.now();
      final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await widget.ref.read(advanceRequestServiceProvider).approve(widget.req.id, date: date);
      if (mounted) Navigator.pop(context, 'approved');
    } catch (e) {
      if (mounted) showError(context, e);
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deny() async {
    setState(() => _loading = true);
    try {
      HapticFeedback.selectionClick();
      await widget.ref.read(advanceRequestServiceProvider).deny(widget.req.id);
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
        CircleAvatar(radius: 32, backgroundColor: cs.primaryContainer, child: PhosphorIcon(PhosphorIconsDuotone.handCoins, size: 32, color: cs.primary)),
        const SizedBox(height: 16),
        Text(widget.req.employeeName, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        Text('Requests an advance of ₹${widget.req.amount.toStringAsFixed(0)}', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Icon(PhosphorIconsRegular.quotes, color: cs.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.req.reason, style: tt.bodyMedium?.copyWith(fontStyle: FontStyle.italic))),
            ],
          ),
        ),
        const SizedBox(height: 32),
        if (_loading)
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: CircularProgressIndicator())
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _deny,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: const BorderSide(color: Color(0xFFEF4444)),
                  ),
                  child: const Text('Deny', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: _approve,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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

  const _AdvanceRequestCard({required this.cs, required this.tt, required this.request, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final isPending = request.isPending;
    final statusColor = isPending ? const Color(0xFFF59E0B) : request.isApproved ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final statusLabel = isPending ? 'Pending Action' : request.isApproved ? 'Approved' : 'Denied';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Icon(isPending ? PhosphorIconsFill.clockUser : PhosphorIconsFill.checkCircle, color: statusColor, size: 12),
                          const SizedBox(width: 6),
                          Text(statusLabel.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                    Text('₹${request.amount.toStringAsFixed(0)}', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: cs.primary, letterSpacing: -1.0)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: cs.primaryContainer.withValues(alpha: 0.5),
                      child: Text(request.employeeName.isNotEmpty ? request.employeeName[0] : '?', style: TextStyle(fontWeight: FontWeight.w800, color: cs.primary)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(request.employeeName, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(request.reason, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    if (isPending) Icon(PhosphorIconsRegular.caretRight, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
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


