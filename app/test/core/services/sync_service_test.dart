import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/services/pending_sync_store.dart';
import 'package:clearwage/core/services/sync_service.dart';

void main() {
  group('PendingSyncStore', () {
    late Directory dir;
    late PendingSyncStore store;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('cw_sync');
      store = PendingSyncStore(overrideDir: dir.path);
    });

    tearDown(() async {
      await dir.delete(recursive: true);
    });

    test('appends, removes, and clears persisted items', () async {
      const item = PendingSyncItem(
        id: '1',
        kind: 'attendance',
        payload: {'records': []},
        createdAt: 1,
      );
      await store.append(item);
      expect(await store.read(), hasLength(1));

      await store.remove('1');
      expect(await store.read(), isEmpty);

      await store.append(item);
      await store.clear();
      expect(await store.read(), isEmpty);
    });
  });

  group('SyncService', () {
    test('flush pushes successful items and keeps failed ones', () async {
      final store = <Map<String, dynamic>>[];
      Future<List<Map<String, dynamic>>> read() async => store;
      Future<void> write(List<Map<String, dynamic>> items) async {
        store
          ..clear()
          ..addAll(List.of(items));
      }

      final pushed = <String>[];
      Future<bool> push(String kind, Map<String, dynamic> payload) async {
        pushed.add(kind);
        return kind == 'attendance';
      }

      final svc = SyncService(read: read, write: write, push: push);

      await svc.enqueue(kind: 'attendance', payload: const {});
      await svc.enqueue(kind: 'ledger', payload: const {});

      final remaining = await svc.flush();

      expect(pushed, containsAll(['attendance', 'ledger']));
      expect(remaining, 1);
      expect(await svc.pendingCount(), 1);
    });

    test('enqueue then clear keeps count at zero', () async {
      final store = <Map<String, dynamic>>[];
      Future<List<Map<String, dynamic>>> read() async => store;
      Future<void> write(List<Map<String, dynamic>> items) async {
        store
          ..clear()
          ..addAll(List.of(items));
      }

      final svc = SyncService(
        read: read,
        write: write,
        push: (kind, payload) async => true,
      );

      await svc.enqueue(kind: 'ledger', payload: const {});
      expect(await svc.pendingCount(), 1);
      store.clear();
      expect(await svc.pendingCount(), 0);
    });
  });
}
