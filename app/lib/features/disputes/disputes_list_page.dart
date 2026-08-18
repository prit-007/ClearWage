import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/services.dart';
import '../../data/models/dispute_model.dart';

final _disputesProvider = FutureProvider.autoDispose<List<Dispute>>((
  ref,
) async {
  final service = ref.watch(disputeServiceProvider);
  return service.list(status: 'open');
});

final _closedDisputesProvider = FutureProvider.autoDispose<List<Dispute>>((
  ref,
) async {
  final service = ref.watch(disputeServiceProvider);
  final resolved = await service.list(status: 'resolved');
  final rejected = await service.list(status: 'rejected');
  return [...resolved, ...rejected];
});

class DisputesListScreen extends ConsumerStatefulWidget {
  const DisputesListScreen({super.key});

  @override
  ConsumerState<DisputesListScreen> createState() => _DisputesListScreenState();
}

class _DisputesListScreenState extends ConsumerState<DisputesListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final openDisputes = ref.watch(_disputesProvider);
    final closedDisputes = ref.watch(_closedDisputesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disputes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Open'),
            Tab(text: 'Closed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          openDisputes.when(
            data: (disputes) => disputes.isEmpty
                ? const Center(child: Text('No open disputes'))
                : RefreshIndicator(
                    onRefresh: () async => ref.invalidate(_disputesProvider),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: disputes.length,
                      itemBuilder: (ctx, i) => _DisputeCard(
                        dispute: disputes[i],
                        onAction: () => ref.invalidate(_disputesProvider),
                      ),
                    ),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
          closedDisputes.when(
            data: (disputes) => disputes.isEmpty
                ? const Center(child: Text('No closed disputes'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: disputes.length,
                    itemBuilder: (ctx, i) =>
                        _DisputeCard(dispute: disputes[i], readOnly: true),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ],
      ),
    );
  }
}

class _DisputeCard extends ConsumerWidget {
  final Dispute dispute;
  final VoidCallback? onAction;
  final bool readOnly;

  const _DisputeCard({
    required this.dispute,
    this.onAction,
    this.readOnly = false,
  });

  Color _statusColor() {
    switch (dispute.status) {
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Raised by ${dispute.raisedByName.isNotEmpty ? dispute.raisedByName : dispute.raisedBy}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    dispute.status.toUpperCase(),
                    style: TextStyle(
                      color: _statusColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(dispute.reason),
            if (dispute.resolutionNote != null) ...[
              const SizedBox(height: 8),
              Text(
                'Resolution: ${dispute.resolutionNote}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
            if (!readOnly && dispute.isOpen) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showResolveDialog(context, ref, isReject: true),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showResolveDialog(context, ref, isReject: false),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Resolve'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showResolveDialog(
    BuildContext context,
    WidgetRef ref, {
    required bool isReject,
  }) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isReject ? 'Reject Dispute' : 'Resolve Dispute'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Resolution note (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final service = ref.read(disputeServiceProvider);
              try {
                if (isReject) {
                  await service.reject(
                    disputeId: dispute.id,
                    resolutionNote: controller.text.isNotEmpty
                        ? controller.text
                        : null,
                  );
                } else {
                  await service.resolve(
                    disputeId: dispute.id,
                    resolutionNote: controller.text.isNotEmpty
                        ? controller.text
                        : null,
                  );
                }
                onAction?.call();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: Text(isReject ? 'Reject' : 'Resolve'),
          ),
        ],
      ),
    );
  }
}
