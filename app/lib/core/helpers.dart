import 'package:flutter/material.dart';

int safeToInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double safeToDouble(dynamic value, [double fallback = 0.0]) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

String getInitials(String name) {
  return name.split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join().toUpperCase();
}

String resolveMediaUrl(String url, String baseUrl) {
  if (url.isEmpty) return url;
  final u = Uri.tryParse(url);
  if (u != null && u.hasScheme) return url;
  return '$baseUrl$url';
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
