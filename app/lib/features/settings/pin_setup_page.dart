import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../core/helpers.dart';
import '../../core/responsive.dart';
import '../../core/services/biometric_service.dart';

class PinSetupPage extends ConsumerStatefulWidget {
  const PinSetupPage({super.key});

  @override
  ConsumerState<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends ConsumerState<PinSetupPage> {
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final pin = _pinCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();
    if (pin.length != 4) {
      showError(context, 'PIN must be 4 digits');
      return;
    }
    if (pin != confirm) {
      showError(context, 'PINs do not match');
      return;
    }
    await ref.read(appLockProvider.notifier).setPin(pin);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PIN saved')));
      if (context.mounted) context.pop();
    }
  }

  Future<void> _remove() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove PIN?',
      message: 'The app will no longer have a PIN fallback.',
      confirmLabel: 'Remove',
      icon: PhosphorIconsRegular.key,
      isDestructive: true,
    );
    if (confirmed != true) return;
    await ref.read(appLockProvider.notifier).clearPin();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PIN removed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hasPin = ref.watch(appLockProvider).pinEnabled;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft, color: cs.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'App PIN',
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: AppScrollPhysics.physics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(PhosphorIconsRegular.key, size: 48, color: cs.primary),
              const SizedBox(height: 12),
              Text(
                hasPin
                    ? 'Change your 4-digit unlock PIN. Used when biometrics fail.'
                    : 'Set a 4-digit unlock PIN as a fallback when biometrics fail.',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              _PinField(controller: _pinCtrl, label: 'New PIN'),
              const SizedBox(height: 16),
              _PinField(controller: _confirmCtrl, label: 'Confirm PIN'),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(PhosphorIconsFill.key),
                label: Text(hasPin ? 'Update PIN' : 'Set PIN'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              if (hasPin) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _remove,
                  icon: const Icon(PhosphorIconsRegular.trash),
                  label: const Text('Remove PIN'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: cs.error,
                    side: BorderSide(color: cs.error.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _PinField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      obscureText: true,
      maxLength: 4,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        letterSpacing: 12,
      ),
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
