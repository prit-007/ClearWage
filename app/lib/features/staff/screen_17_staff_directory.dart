import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StaffDirectoryScreen extends StatefulWidget {
  const StaffDirectoryScreen({super.key});
  @override
  State<StaffDirectoryScreen> createState() => _StaffDirectoryScreenState();
}

class _StaffDirectoryScreenState extends State<StaffDirectoryScreen> {
  final _searchController = TextEditingController();

  final _employees = [
    _Staff(name: 'Amit Singh', role: 'Operator', dept: 'Production'),
    _Staff(name: 'Anita Gupta', role: 'Supervisor', dept: 'Quality'),
    _Staff(name: 'Deepa Joshi', role: 'Operator', dept: 'Packing'),
    _Staff(name: 'Gopal Iyer', role: 'Technician', dept: 'Maintenance'),
    _Staff(name: 'Kavita Nair', role: 'Operator', dept: 'Production'),
    _Staff(name: 'Manoj Tiwari', role: 'Supervisor', dept: 'Production'),
    _Staff(name: 'Priya Patel', role: 'Operator', dept: 'Packing'),
    _Staff(name: 'Rahul Sharma', role: 'Manager', dept: 'Production'),
    _Staff(name: 'Ravi Verma', role: 'Technician', dept: 'Maintenance'),
    _Staff(name: 'Sunita Devi', role: 'Operator', dept: 'Quality'),
    _Staff(name: 'Suresh Rao', role: 'Supervisor', dept: 'Packing'),
    _Staff(name: 'Vijay Kumar', role: 'Operator', dept: 'Production'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Directory')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              controller: _searchController,
              leading: const Icon(Icons.search),
              hintText: 'Search employees...',
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(cs.surfaceContainerHigh),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: _alphabeticalGroups.length,
              itemBuilder: (_, i) {
                final group = _alphabeticalGroups.keys.elementAt(i);
                final items = _alphabeticalGroups[group]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Text(group, style: tt.titleSmall?.copyWith(
                        color: cs.primary, fontWeight: FontWeight.bold,
                      )),
                    ),
                    ...items.map((e) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: CircleAvatar(
                        backgroundColor: cs.primaryContainer,
                        child: Text(
                          e.name.split(' ').map((e) => e[0]).take(2).join(),
                          style: TextStyle(color: cs.onPrimaryContainer),
                        ),
                      ),
                      title: Text(e.name, style: tt.bodyLarge),
                      subtitle: Text('${e.role} - ${e.dept}', style: tt.bodySmall),
                      trailing: Icon(Icons.chevron_right,
                          color: cs.onSurface.withValues(alpha: 0.4)),
                      onTap: () => context.push('/staff/${e.name}'),
                    )),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<_Staff>> get _alphabeticalGroups {
    final map = <String, List<_Staff>>{};
    for (final e in _employees) {
      final letter = e.name[0].toUpperCase();
      map.putIfAbsent(letter, () => []).add(e);
    }
    return Map.fromEntries(map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key)));
  }
}

class _Staff {
  final String name, role, dept;
  const _Staff({required this.name, required this.role, required this.dept});
}
