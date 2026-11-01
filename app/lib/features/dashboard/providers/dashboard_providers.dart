import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/dashboard_model.dart';
import '../../../core/providers/services.dart';

final dashboardDataProvider = FutureProvider.autoDispose<DashboardData>((ref) {
  return ref.watch(dashboardServiceProvider).get();
});
