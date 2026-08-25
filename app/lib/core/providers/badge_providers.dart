import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../providers/services.dart';

final openDisputesCountProvider = FutureProvider.autoDispose<int>((ref) async {
  ref.watch(tokenProvider);
  try {
    final disputes = await ref
        .watch(disputeServiceProvider)
        .list(status: 'open');
    return disputes.length;
  } catch (_) {
    return 0;
  }
});

final pendingAdvancesCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  ref.watch(tokenProvider);
  try {
    final advances = await ref
        .watch(advanceRequestServiceProvider)
        .list(status: 'pending');
    return advances.length;
  } catch (_) {
    return 0;
  }
});
