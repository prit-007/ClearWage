import 'package:flutter/material.dart';
import '../helpers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_config.dart';

class EmployeeAvatar extends ConsumerStatefulWidget {
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
  ConsumerState<EmployeeAvatar> createState() => _EmployeeAvatarState();
}

class _EmployeeAvatarState extends ConsumerState<EmployeeAvatar> {
  bool _failed = false;

  @override
  void didUpdateWidget(EmployeeAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoUrl != widget.photoUrl) {
      _failed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initials = getInitials(widget.name);
    final resolved = (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
        ? resolveMediaUrl(widget.photoUrl!, ref.watch(serverUrlProvider))
        : '';
    final showImage = resolved.isNotEmpty && !_failed;

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor:
          widget.backgroundColor ??
          cs.surfaceContainerHighest.withValues(alpha: 0.5),
      foregroundColor: widget.textColor ?? cs.onSurface,
      backgroundImage: showImage ? NetworkImage(resolved) : null,
      onBackgroundImageError: resolved.isNotEmpty
          ? (_, _) => setState(() => _failed = true)
          : null,
      child: showImage
          ? null
          : Text(
              initials,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: widget.textColor ?? cs.onSurface,
                fontSize: widget.fontSize ?? widget.radius * 0.7,
              ),
            ),
    );
  }
}
