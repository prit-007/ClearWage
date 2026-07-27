import 'package:flutter/material.dart';

String getInitials(String name) {
  return name.split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join().toUpperCase();
}

void showError(BuildContext context, Object? e) {
  if (context.mounted) {
    final msg = e is FlutterError ? e.message : '$e';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Theme.of(context).colorScheme.error,
    ));
  }
}

void showSuccess(BuildContext context, String msg) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

Widget sheetHandle(ColorScheme cs) {
  return Container(
    width: 40, height: 4,
    decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)),
  );
}
