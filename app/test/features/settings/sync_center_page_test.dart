import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/providers/sync_providers.dart';
import 'package:clearwage/core/services/connectivity_service.dart';
import 'package:clearwage/core/services/pending_sync_store.dart';
import 'package:clearwage/features/settings/sync_center_page.dart';

class FakeConnectivity extends ConnectivityNotifier {
  @override
  Stream<bool> build() async* {
    yield true;
  }
}

class StubSyncStore extends PendingSyncStore {
  final List<PendingSyncItem> items;

  StubSyncStore(this.items);

  @override
  Future<List<PendingSyncItem>> read() async => items;
}

void main() {
  testWidgets('renders sync center status and force sync button', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityProvider.overrideWith(FakeConnectivity.new),
          pendingSyncStoreProvider.overrideWithValue(
            StubSyncStore(const [
              PendingSyncItem(
                id: '1',
                kind: 'attendance',
                payload: {'records': []},
                createdAt: 1,
              ),
            ]),
          ),
          pendingSyncCountProvider.overrideWith((ref) => 1),
        ],
        child: const MaterialApp(home: SyncCenterPage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Sync Center'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('1 change awaiting sync'), findsOneWidget);
    expect(find.text('Force Sync Now'), findsOneWidget);
    expect(find.text('Attendance'), findsOneWidget);
  });
}