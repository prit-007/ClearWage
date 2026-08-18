import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/core/api_client.dart';
import 'package:vivek_app/core/providers/services.dart';
import 'package:vivek_app/data/models/dispute_model.dart';
import 'package:vivek_app/data/services/dispute_service.dart';
import 'package:vivek_app/features/disputes/disputes_list_page.dart';

class _NoOpApiClient extends ApiClient {
  _NoOpApiClient() : super(baseUrl: 'http://localhost');
}

class FakeDisputeService extends DisputeService {
  List<Dispute> _openDisputes = [];
  List<Dispute> _resolvedDisputes = [];
  List<Dispute> _rejectedDisputes = [];
  Object? _error;

  FakeDisputeService() : super(_NoOpApiClient());

  void setOpenDisputes(List<Dispute> disputes) => _openDisputes = disputes;
  void setResolvedDisputes(List<Dispute> disputes) =>
      _resolvedDisputes = disputes;
  void setRejectedDisputes(List<Dispute> disputes) =>
      _rejectedDisputes = disputes;
  void setError(Object error) => _error = error;

  @override
  Future<List<Dispute>> list({String status = 'open'}) async {
    if (_error != null) throw _error!;
    switch (status) {
      case 'resolved':
        return _resolvedDisputes;
      case 'rejected':
        return _rejectedDisputes;
      default:
        return _openDisputes;
    }
  }
}

Widget _buildApp(FakeDisputeService fakeService) {
  return ProviderScope(
    overrides: [disputeServiceProvider.overrideWithValue(fakeService)],
    child: const MaterialApp(home: DisputesListScreen()),
  );
}

void main() {
  group('DisputesListScreen', () {
    late FakeDisputeService fakeService;

    setUp(() {
      fakeService = FakeDisputeService();
    });

    testWidgets('shows open and closed tabs', (tester) async {
      fakeService.setOpenDisputes([]);
      fakeService.setResolvedDisputes([]);
      fakeService.setRejectedDisputes([]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Disputes'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Closed'), findsOneWidget);
    });

    testWidgets('shows empty state for open disputes', (tester) async {
      fakeService.setOpenDisputes([]);
      fakeService.setResolvedDisputes([]);
      fakeService.setRejectedDisputes([]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('No open disputes'), findsOneWidget);
    });

    testWidgets('shows dispute list when open disputes exist', (tester) async {
      fakeService.setOpenDisputes([
        Dispute(
          id: 'd-1',
          ledgerId: 'l-1',
          employeeId: 'emp-1',
          raisedBy: 'emp-1',
          reason: 'Incorrect wage calculation for August',
          status: 'open',
          raisedByName: 'Rahul Kumar',
        ),
        Dispute(
          id: 'd-2',
          ledgerId: 'l-2',
          employeeId: 'emp-2',
          raisedBy: 'emp-2',
          reason: 'Missing overtime pay',
          status: 'open',
          raisedByName: 'Priya Sharma',
        ),
      ]);
      fakeService.setResolvedDisputes([]);
      fakeService.setRejectedDisputes([]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Raised by Rahul Kumar'), findsOneWidget);
      expect(find.text('Raised by Priya Sharma'), findsOneWidget);
      expect(
        find.text('Incorrect wage calculation for August'),
        findsOneWidget,
      );
      expect(find.text('Missing overtime pay'), findsOneWidget);
      expect(find.text('OPEN'), findsWidgets);
    });

    testWidgets('shows closed disputes on Closed tab', (tester) async {
      fakeService.setOpenDisputes([]);
      fakeService.setResolvedDisputes([
        Dispute(
          id: 'd-3',
          ledgerId: 'l-3',
          employeeId: 'emp-3',
          raisedBy: 'emp-3',
          reason: 'Wrong date on ledger',
          status: 'resolved',
          raisedByName: 'Amit Singh',
          resolutionNote: 'Fixed the date',
        ),
      ]);
      fakeService.setRejectedDisputes([]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Closed'));
      await tester.pumpAndSettle();

      expect(find.text('Raised by Amit Singh'), findsOneWidget);
      expect(find.text('Wrong date on ledger'), findsOneWidget);
      expect(find.text('Resolution: Fixed the date'), findsOneWidget);
      expect(find.text('RESOLVED'), findsOneWidget);
    });

    testWidgets('shows empty state for closed disputes', (tester) async {
      fakeService.setOpenDisputes([]);
      fakeService.setResolvedDisputes([]);
      fakeService.setRejectedDisputes([]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Closed'));
      await tester.pumpAndSettle();

      expect(find.text('No closed disputes'), findsOneWidget);
    });
  });
}
