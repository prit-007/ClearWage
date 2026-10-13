import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/pending_sync_store.dart';
import '../../core/services/sync_service.dart';
import 'services.dart';

final pendingSyncStoreProvider = Provider<PendingSyncStore>((ref) {
  return PendingSyncStore();
});

final pendingSyncCountProvider = StateProvider<int>((ref) => 0);

Future<void> refreshPendingSyncCount(WidgetRef ref) async {
  final items = await ref.read(pendingSyncStoreProvider).read();
  ref.read(pendingSyncCountProvider.notifier).state = items.length;
}

/// Uploads any queued KYC documents (staged offline) after connectivity returns.
Future<void> flushDocumentUploads(WidgetRef ref) async {
  try {
    final queue = ref.read(documentUploadQueueProvider);
    final docs = ref.read(documentServiceProvider);
    final pending = await queue.pending();
    for (final item in pending) {
      try {
        await docs.uploadDocument(
          employeeId: item.employeeId,
          docType: item.docType,
          filePath: item.filePath,
        );
        await queue.remove(item.employeeId, item.docType);
      } catch (_) {
        // Leave queued for the next reconnect/retry.
      }
    }
  } catch (_) {}
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final store = ref.watch(pendingSyncStoreProvider);
  final attendance = ref.watch(attendanceServiceProvider);
  final ledger = ref.watch(ledgerServiceProvider);

  Future<List<Map<String, dynamic>>> read() async {
    final items = await store.read();
    return items.map((e) => e.toJson()).toList();
  }

  Future<void> write(List<Map<String, dynamic>> items) async {
    final fileItems = items
        .map(
          (e) => PendingSyncItem.fromJson({
            'id': e['id'],
            'kind': e['kind'],
            'payload': e['payload'],
            'created_at': e['created_at'],
          }),
        )
        .toList();
    await store.clear();
    for (final i in fileItems) {
      await store.append(i);
    }
  }

  Future<bool> push(String kind, Map<String, dynamic> payload) async {
    if (kind == 'attendance') {
      final records = (payload['records'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      if (records.isEmpty) return true;
      await attendance.bulkUpsert(records);
      return true;
    }
    if (kind == 'ledger') {
      await ledger.create(payload);
      return true;
    }
    return false;
  }

  return SyncService(read: read, write: write, push: push);
});
