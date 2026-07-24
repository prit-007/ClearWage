import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import '../../core/app_config.dart';
import '../../providers/providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(text: '+91');
  final _factoryCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _sentOtp = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _factoryCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your name');
      return;
    }
    if (_factoryCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your factory name');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).requestOtp(_phoneCtrl.text.trim());
      setState(() { _sentOtp = true; _loading = false; });
    } catch (e) {
      setState(() {
        _error = 'Cannot reach server. Check your connection or server address.';
        _loading = false;
      });
    }
  }

  Future<void> _register() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await ref.read(authServiceProvider).register(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        factoryName: _factoryCtrl.text.trim(),
        otp: _otpCtrl.text.trim(),
      );
      ref.read(tokenProvider.notifier).state = token.token;
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _showServerDialog() {
    final urlCtrl = TextEditingController(text: ref.read(serverUrlProvider));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24, right: 24, top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Server Configuration', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: urlCtrl,
              decoration: InputDecoration(
                labelText: 'Server Address',
                hintText: 'http://192.168.1.100:8081',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                ref.read(serverUrlProvider.notifier).state = urlCtrl.text.trim();
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('Save Configuration'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
    );

    InputDecoration inputDeco(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: cs.onSurfaceVariant),
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined),
            tooltip: 'Server Settings',
            onPressed: _showServerDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.business_outlined, size: 56, color: cs.primary),
                const SizedBox(height: 24),
                Text('Set up your factory', style: tt.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                )),
                const SizedBox(height: 8),
                Text('Create an owner account to get started.',
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 32),

                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameCtrl,
                        enabled: !_sentOtp,
                        decoration: inputDeco('Your Name', Icons.person_outlined),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        enabled: !_sentOtp,
                        decoration: inputDeco('Phone Number', Icons.phone_outlined),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _factoryCtrl,
                        enabled: !_sentOtp,
                        decoration: inputDeco('Factory Name', Icons.factory_outlined),
                      ),

                      if (_sentOtp) ...[
                        const SizedBox(height: 32),
                        Text('Enter the 6-digit code sent to your phone',
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                        const SizedBox(height: 16),
                        Pinput(
                          controller: _otpCtrl,
                          length: 6,
                          defaultPinTheme: defaultPinTheme,
                          focusedPinTheme: defaultPinTheme.copyWith(
                            decoration: defaultPinTheme.decoration?.copyWith(
                              border: Border.all(color: cs.primary),
                              color: cs.surface,
                            ),
                          ),
                          onCompleted: (pin) => _register(),
                        ),
                      ],

                      if (_error != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_rounded, color: cs.onErrorContainer, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(_error!,
                                  style: tt.bodySmall?.copyWith(color: cs.onErrorContainer)
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _loading ? null : (_sentOtp ? _register : _requestOtp),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(height: 24, width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Text(
                          _sentOtp ? 'Create Account' : 'Send OTP',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),

                if (!_sentOtp) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account? ",
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
