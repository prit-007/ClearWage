import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PremiumMacroField extends StatefulWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final String label, subtitle;
  final TextEditingController ctrl;
  final IconData icon;
  final Color activeColor;

  const PremiumMacroField({super.key, required this.cs, required this.tt, required this.label, required this.subtitle, required this.ctrl, required this.icon, required this.activeColor});

  @override
  State<PremiumMacroField> createState() => _PremiumMacroFieldState();
}

class _PremiumMacroFieldState extends State<PremiumMacroField> {
  final FocusNode _focus = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      setState(() => _isFocused = _focus.hasFocus);
      if (_isFocused) HapticFeedback.selectionClick();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isFocused ? widget.activeColor.withValues(alpha: 0.05) : widget.cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _isFocused ? widget.activeColor : widget.cs.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: _isFocused ? [BoxShadow(color: widget.activeColor.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 8))] : [],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: widget.activeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(widget.icon, color: widget.activeColor, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label, style: widget.tt.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                Text(widget.subtitle, style: widget.tt.bodySmall?.copyWith(color: widget.cs.onSurfaceVariant)),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: TextField(
              controller: widget.ctrl,
              focusNode: _focus,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: widget.tt.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: widget.activeColor, letterSpacing: -1.0),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: widget.cs.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (_) => HapticFeedback.selectionClick(),
            ),
          ),
        ],
      ),
    );
  }
}
