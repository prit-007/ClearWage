import 'dart:async';

/// A codegen-free offline write queue. Offline attendance/ledger writes are
/// staged here and flushed to the server when connectivity returns.
class SyncService {
  SyncService({required this.read, required this.write, required this.push});

  final Future<List<Map<String, dynamic>>> Function() read;
  final Future<void> Function(List<Map<String, dynamic>>) write;
  final Future<bool> Function(String kind, Map<String, dynamic> payload) push;
  Future<void> _tail = Future.value();

  /// Chains [action] after all previously queued actions so overlapping
  /// flush() calls never rewrite the queue list concurrently.
  Future<T> _exclusive<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<void> enqueue({
    required String kind,
    required Map<String, dynamic> payload,
  }) async {
    final items = await read();
    items.add({
      'id': '${DateTime.now().microsecondsSinceEpoch}_$kind',
      'kind': kind,
      'payload': payload,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    await write(List.of(items));
  }

  Future<int> pendingCount() async => (await read()).length;

  /// Attempts to push all pending items; returns the number still pending.
  /// Serialized so reconnect auto-flush and a manual Force Sync never overlap.
  Future<int> flush() {
    return _exclusive(() async {
      final items = await read();
      final remaining = <Map<String, dynamic>>[];
      for (final item in items) {
        try {
          final ok = await push(
            item['kind'] as String? ?? '',
            (item['payload'] as Map<String, dynamic>?) ?? {},
          );
          if (!ok) remaining.add(item);
        } catch (_) {
          remaining.add(item);
        }
      }
      await write(remaining);
      return remaining.length;
    });
  }
}
