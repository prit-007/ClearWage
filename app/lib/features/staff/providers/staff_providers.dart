import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/employee_model.dart';
import '../../../core/providers/services.dart';

final employeeListProvider = FutureProvider.autoDispose<List<Employee>>((ref) {
  return ref.watch(staffServiceProvider).list(limit: 200);
});
