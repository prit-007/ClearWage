import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FirebasePhoneField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;

  const FirebasePhoneField({
    super.key,
    required this.controller,
    required this.label,
    this.enabled = true,
  });

  @override
  State<FirebasePhoneField> createState() => _FirebasePhoneFieldState();
}

class _FirebasePhoneFieldState extends State<FirebasePhoneField> {
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
        validator: (value) {
          final text = widget.controller.text.trim();
          if (text.isEmpty) return 'Enter your mobile number';
          if (text.length != 10) return 'Number must be exactly 10 digits';
          return null;
        },
        builder: (FormFieldState<String> state) {
          final hasError = state.hasError;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: hasError ? cs.error : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '\u{1F1EE}\u{1F1F3}',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+91',
                            style: tt.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.phone,
                        enabled: widget.enabled,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        style: tt.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: widget.enabled
                              ? cs.onSurface
                              : cs.onSurfaceVariant,
                        ),
                        onChanged: (val) {
                          state.didChange(val);
                          if (val.length == 10) {
                            HapticFeedback.lightImpact();
                            _focusNode.unfocus();
                          }
                        },
                        decoration: InputDecoration(
                          hintText: '98765 43210',
                          hintStyle: TextStyle(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
