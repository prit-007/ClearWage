import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneCtrl = TextEditingController(text: '+91');
  final _otpCtrl = TextEditingController();
  bool _sentOtp = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).requestOtp(_phoneCtrl.text.trim());
      setState(() { _sentOtp = true; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _verifyOtp() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await ref.read(authServiceProvider).verifyOtp(
        _phoneCtrl.text.trim(),
        _otpCtrl.text.trim(),
      );
      ref.read(tokenProvider.notifier).state = token.token;
      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 60),
            Icon(Icons.factory_outlined, size: 72, color: cs.primary),
            const SizedBox(height: 16),
            Text('Factory Workforce', style: tt.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 8),
            Text('Sign in to manage your workforce',
                style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 48),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixText: '',
              ),
            ),
            if (_sentOtp) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'OTP',
                  counterText: '',
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: cs.error, fontSize: 13)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : (_sentOtp ? _verifyOtp : _requestOtp),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_sentOtp ? 'Verify OTP' : 'Send OTP'),
            ),
            if (!_sentOtp) ...[
              const SizedBox(height: 16),
              Text('OTP will be sent via SMS',
                  textAlign: TextAlign.center,
                  style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.4))),
            ],
          ],
        ),
      ),
    );
  }
}
