import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class ValidatedField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final Object? prefixIcon;
  final TextInputType? keyboardType;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final int? maxLines;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;

  const ValidatedField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.keyboardType,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.maxLines,
    this.validator,
    this.onChanged,
    this.onTap,
  });

  @override
  State<ValidatedField> createState() => _ValidatedFieldState();
}

class _ValidatedFieldState extends State<ValidatedField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
      if (_isFocused) HapticFeedback.selectionClick();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: FormField<String>(
        initialValue: widget.controller.text,
        validator: widget.validator,
        builder: (FormFieldState<String> state) {
          final hasError = state.hasError;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. External, Static Label (Premium SaaS Standard)
              Text(
                widget.label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: hasError ? cs.error : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),

              // 2. Animated Container for Tactile Focus States
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: !widget.enabled
                      ? cs.surfaceContainerHighest.withValues(alpha: 0.1)
                      : _isFocused
                      ? cs.primary.withValues(alpha: 0.02)
                      : cs.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasError
                        ? cs.error.withValues(alpha: _isFocused ? 1.0 : 0.5)
                        : _isFocused
                        ? cs.primary
                        : cs.outlineVariant.withValues(alpha: 0.3),
                    width: _isFocused || hasError ? 2 : 1,
                  ),
                  boxShadow: _isFocused && !hasError
                      ? [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  keyboardType: widget.keyboardType,
                  enabled: widget.enabled,
                  readOnly: widget.readOnly,
                  obscureText: widget.obscureText,
                  maxLines: widget.maxLines,
                  style: tt.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: widget.enabled ? cs.onSurface : cs.onSurfaceVariant,
                  ),
                  onTap: widget.readOnly ? widget.onTap : null,
                  onChanged: (val) {
                    state.didChange(val);
                    if (widget.onChanged != null) widget.onChanged!(val);
                  },
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: TextStyle(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    prefixIcon: widget.prefixIcon != null
                        ? PhosphorIcon(
                            widget.prefixIcon!,
                            size: 20,
                            color: hasError
                                ? cs.error
                                : _isFocused
                                ? cs.primary
                                : cs.onSurfaceVariant,
                          )
                        : null,
                  ),
                ),
              ),

              // 3. Clean Error State Display
              if (hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 14,
                        color: cs.error,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        state.errorText!,
                        style: TextStyle(
                          color: cs.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
