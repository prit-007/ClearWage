import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/employee_model.dart';
import '../../providers/providers.dart';

final staffListProvider = FutureProvider.autoDispose<List<Employee>>((ref) {
  return ref.watch(staffServiceProvider).list();
});

class StaffDirectoryScreen extends ConsumerWidget {
  const StaffDirectoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final async = ref.watch(staffListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Directory')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('$e', style: TextStyle(color: cs.error), textAlign: TextAlign.center),
          ),
        ),
        data: (employees) {
          final grouped = _groupByLetter(employees);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Text(entry.key, style: tt.titleSmall?.copyWith(
                      color: cs.primary, fontWeight: FontWeight.bold,
                    )),
                  ),
                  ...entry.value.map((e) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: CircleAvatar(
                      backgroundColor: cs.primaryContainer,
                      child: Text(
                        e.name.split(' ').map((e) => e[0]).take(2).join(),
                        style: TextStyle(color: cs.onPrimaryContainer),
                      ),
                    ),
                    title: Text(e.name, style: tt.bodyLarge),
                    subtitle: Text(
                      '${e.designation ?? e.role}',
                      style: tt.bodySmall,
                    ),
                    trailing: Icon(Icons.chevron_right,
                        color: cs.onSurface.withValues(alpha: 0.4)),
                  )),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Map<String, List<Employee>> _groupByLetter(List<Employee> employees) {
    final map = <String, List<Employee>>{};
    for (final e in employees) {
      final letter = e.name.isNotEmpty ? e.name[0].toUpperCase() : '#';
      map.putIfAbsent(letter, () => []).add(e);
    }
    final sorted = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return {for (final e in sorted) e.key: e.value};
  }
}
