import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../services/biometric_service.dart';

/// Lock screen overlay shown when the app is locked.
class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  bool _showPin = false;
  final _pinCtrl = TextEditingController();
  final _pinFocus = FocusNode();

  @override
  void dispose() {
    _pinCtrl.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  Future<void> _unlockPin() async {
    final code = _pinCtrl.text.trim();
    if (code.length != 4) return;
    final ok = await ref.read(appLockProvider.notifier).verifyPin(code);
    if (mounted && !ok) {
      _pinCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect PIN. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _showPin ? PhosphorIconsFill.key : PhosphorIconsFill.lock,
                    size: 48,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'ClearWage is locked',
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _showPin ? 'Enter your PIN' : 'Authenticate to continue',
                  style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 40),
                if (_showPin) ...[
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: _pinCtrl,
                      focusNode: _pinFocus,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      obscureText: true,
                      textAlign: TextAlign.center,
                      maxLength: 4,
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 12,
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _unlockPin(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _unlockPin,
                    icon: const Icon(PhosphorIconsFill.arrowRight),
                    label: const Text('Unlock'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  if (lockState.biometricsAvailable) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() => _showPin = false),
                      child: const Text('Use biometrics instead'),
                    ),
                  ],
                ] else ...[
                  if (lockState.biometricsAvailable)
                    FilledButton.icon(
                      onPressed: () async {
                        final result = await ref
                            .read(appLockProvider.notifier)
                            .authenticate();
                        if (!result && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Authentication failed. Try again.',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(PhosphorIconsFill.fingerprint),
                      label: const Text(
                        'Unlock with Biometrics',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    )
                  else
                    Text(
                      lockState.pinEnabled
                          ? 'Biometrics not available'
                          : 'Biometrics not available on this device',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  if (lockState.pinEnabled) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showPin = true;
                          _pinCtrl.clear();
                        });
                      },
                      icon: const Icon(PhosphorIconsFill.key),
                      label: const Text('Use PIN instead'),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
