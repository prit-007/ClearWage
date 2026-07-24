import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_config.dart';
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
      setState(() { _error = 'Cannot reach server.\nTap the server icon above to set the correct IP address.\n\n$e'; _loading = false; });
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

  void _showServerDialog() {
    final urlCtrl = TextEditingController(text: ref.read(serverUrlProvider));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Server Address'),
        content: TextField(
          controller: urlCtrl,
          decoration: const InputDecoration(
            labelText: 'http://IP:PORT',
            hintText: 'e.g. http://192.168.1.100:8081',
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () {
            ref.read(serverUrlProvider.notifier).state = urlCtrl.text.trim();
            Navigator.pop(context);
          }, child: const Text('Save')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final serverUrl = ref.watch(serverUrlProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dns_outlined),
            tooltip: 'Server: $serverUrl',
            onPressed: _showServerDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 40),
            Icon(Icons.factory_outlined, size: 72, color: cs.primary),
            const SizedBox(height: 16),
            Text('Factory Workforce', style: tt.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 8),
            Text('Sign in to manage your workforce',
                style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 12),
            Center(
              child: Text(serverUrl, style: tt.labelSmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.3),
              )),
            ),
            const SizedBox(height: 36),
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
