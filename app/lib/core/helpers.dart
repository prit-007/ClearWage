import 'package:flutter/material.dart';
import 'api_exceptions.dart';

List<Map<String, dynamic>> asMapList(dynamic data) {
  if (data is! List) return const [];
  final out = <Map<String, dynamic>>[];
  for (final e in data) {
    if (e is Map) {
      try {
        out.add(Map<String, dynamic>.from(e));
      } catch (_) {}
    }
  }
  return out;
}

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

String _ordinal(int day) {
  if (day >= 11 && day <= 13) return '${day}th';
  switch (day % 10) {
    case 1:
      return '${day}st';
    case 2:
      return '${day}nd';
    case 3:
      return '${day}rd';
    default:
      return '${day}th';
  }
}

const _months = [
  '',
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String formatDate(dynamic date) {
  DateTime? dt;
  if (date is DateTime) {
    dt = date;
  } else if (date is String) {
    dt = DateTime.tryParse(date);
  }
  if (dt == null) return '$date';
  final now = DateTime.now();
  final day = _ordinal(dt.day);
  final month = _months[dt.month];
  if (dt.year == now.year) {
    return '$day $month';
  }
  return '$day $month, ${dt.year}';
}

String formatTime(dynamic time) {
  if (time == null || time == '') return '';
  final s = time.toString();
  final parts = s.split(':');
  if (parts.length < 2) return s;
  final h = int.tryParse(parts[0]) ?? 0;
  final m = parts[1];
  final sec = parts.length >= 3 ? parts[2] : '';
  final hasSec = sec.isNotEmpty && sec != '00';
  final String base;
  if (h == 0) {
    base = '12:$m AM';
  } else if (h < 12) {
    base = '$h:$m AM';
  } else if (h == 12) {
    base = '12:$m PM';
  } else {
    base = '${h - 12}:$m PM';
  }
  return hasSec ? '$base:$sec' : base;
}

String getInitials(String name) {
  final initials = name
      .split(' ')
      .where((e) => e.isNotEmpty)
      .map((e) => e[0])
      .take(2)
      .join()
      .toUpperCase();
  return initials.isEmpty ? '?' : initials;
}

String resolveMediaUrl(String url, String baseUrl) {
  if (url.isEmpty) return url;
  final u = Uri.tryParse(url);
  if (u != null && u.hasScheme) return url;
  if (url.startsWith('//')) {
    final scheme = Uri.tryParse(baseUrl)?.scheme ?? 'https';
    return '$scheme:$url';
  }
  final base = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
  final path = url.startsWith('/') ? url : '/$url';
  return '$base$path';
}

String friendlyError(Object? e) {
  if (e == null) return 'Something went wrong';
  if (e is ApiException) {
    final m = e.message.trim();
    return m.isEmpty ? 'Something went wrong' : m;
  }
  if (e is FlutterError) return e.message;
  final m = '$e'.trim();
  return m.length > 200 ? '${m.substring(0, 200)}...' : m;
}

void showError(BuildContext context, Object? e) {
  if (context.mounted) {
    final msg = friendlyError(e);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

void showSuccess(BuildContext context, String msg) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

Widget sheetHandle(ColorScheme cs) {
  return Container(
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: cs.outlineVariant,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  IconData? icon,
  Color? iconColor,
  Color? confirmColor,
  bool isDestructive = false,
}) {
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;
  final effectiveIconColor =
      iconColor ?? (isDestructive ? cs.error : cs.primary);
  final effectiveConfirmColor =
      confirmColor ?? (isDestructive ? cs.error : cs.primary);

  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: icon != null
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: effectiveIconColor),
            )
          : null,
      title: Text(
        title,
        style: tt.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        textAlign: TextAlign.center,
      ),
      content: Text(
        message,
        style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: effectiveConfirmColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            confirmLabel,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

Future<void> showInfoDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String buttonLabel,
  IconData? icon,
  Color? iconColor,
  VoidCallback? onButtonPressed,
}) {
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;
  final effectiveIconColor = iconColor ?? cs.primary;

  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: icon != null
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: effectiveIconColor),
            )
          : null,
      title: Text(
        title,
        style: tt.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        textAlign: TextAlign.center,
      ),
      content: Text(
        message,
        style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            onButtonPressed?.call();
          },
          style: FilledButton.styleFrom(
            backgroundColor: effectiveIconColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(120, 44),
          ),
          child: Text(
            buttonLabel,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
