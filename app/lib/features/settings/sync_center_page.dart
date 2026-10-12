import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../core/providers/sync_providers.dart';
import '../../core/responsive.dart';
import '../../core/design_tokens.dart';
import '../../core/services/connectivity_service.dart';

class SyncCenterPage extends ConsumerStatefulWidget {
  const SyncCenterPage({super.key});

  @override
  ConsumerState<SyncCenterPage> createState() => _SyncCenterPageState();
}

class _SyncCenterPageState extends ConsumerState<SyncCenterPage> {
  bool _syncing = false;

  Future<void> _syncNow() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    final remaining = await ref.read(syncServiceProvider).flush();
    await refreshPendingSyncCount(ref);
    if (mounted) {
      setState(() => _syncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            remaining == 0 ? 'All changes synced' : '$remaining failed to sync',
          ),
        ),
      );
    }
  }

  String _kindLabel(String kind) =>
      kind == 'attendance' ? 'Attendance' : 'Ledger';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final online = ref.watch(connectivityProvider).value ?? false;
    final pending = ref.watch(pendingSyncCountProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft, color: cs.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Sync Center',
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: AppScrollPhysics.physics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (online ? AppColors.success : AppColors.danger)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        online
                            ? PhosphorIconsFill.cloudCheck
                            : PhosphorIconsFill.cloudSlash,
                        color: online ? AppColors.success : AppColors.danger,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            online ? 'Connected' : 'Offline',
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pending == 0
                                ? 'No pending changes'
                                : '$pending change${pending == 1 ? '' : 's'} awaiting sync',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (pending > 0) ...[
                Text(
                  'Pending Items',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder(
                  future: ref.read(pendingSyncStoreProvider).read(),
                  builder: (context, snapshot) {
                    final items = snapshot.data ?? const [];
                    return Column(
                      children: [
                        for (final item in items)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cs.outlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  item.kind == 'attendance'
                                      ? PhosphorIconsRegular.calendarCheck
                                      : PhosphorIconsRegular.coins,
                                  size: 18,
                                  color: cs.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _kindLabel(item.kind),
                                    style: tt.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  _isoTime(item.createdAt),
                                  style: tt.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
              FilledButton.icon(
                onPressed: online && !_syncing ? _syncNow : null,
                icon: _syncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(PhosphorIconsFill.cloudArrowUp),
                label: Text(
                  _syncing ? 'Syncing…' : 'Force Sync Now',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              if (!online) ...[
                const SizedBox(height: 12),
                Text(
                  'You are offline. Changes will sync automatically when the connection returns.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _isoTime(int epochMillis) {
  final d = DateTime.fromMillisecondsSinceEpoch(epochMillis).toLocal();
  return '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}
