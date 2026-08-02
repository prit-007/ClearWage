import 'package:flutter/material.dart';
import '../helpers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_config.dart';

class EmployeeAvatar extends ConsumerWidget {
  final String name;
  final String? photoUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;

  const EmployeeAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 20,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final initials = getInitials(name);
    final resolved = (photoUrl != null && photoUrl!.isNotEmpty)
        ? resolveMediaUrl(photoUrl!, ref.watch(serverUrlProvider))
        : '';

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? cs.surfaceContainerHighest.withValues(alpha: 0.5),
      backgroundImage: resolved.isNotEmpty ? NetworkImage(resolved) : null,
      child: resolved.isNotEmpty
          ? null
          : Text(
              initials,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: textColor ?? cs.onSurface,
                fontSize: fontSize ?? radius * 0.7,
              ),
            ),
    );
  }
}
