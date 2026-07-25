import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import '../../core/widgets/validated_field.dart';
import '../../providers/providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(text: '+91');
  final _factoryCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _otpFocusNode = FocusNode();

  bool _sentOtp = false;
  bool _loading = false;
  String? _error;
  String? _verificationId;

  late AnimationController _iconAnim;
  late Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _iconAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _iconScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _iconAnim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _iconAnim.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _factoryCtrl.dispose();
    _otpCtrl.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _onAutoSignIn(PhoneAuthCredential credential) {
    _handleFirebaseCredential(credential);
  }

  Future<void> _handleFirebaseCredential(PhoneAuthCredential credential) async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Failed to get Firebase user');
      final idToken = await user.getIdToken();
      if (idToken == null) throw Exception('Failed to get Firebase ID token');
      final token = await ref.read(authServiceProvider).register(
        name: _nameCtrl.text.trim(),
        factoryName: _factoryCtrl.text.trim(),
        idToken: idToken,
      );
      ref.read(tokenProvider.notifier).state = token.token;
      HapticFeedback.heavyImpact();
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/onboarding', (_) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _requestOtp() async {
    HapticFeedback.mediumImpact();
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your name');
      return;
    }
    if (_factoryCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your factory name');
      return;
    }
    setState(() { _loading = true; _error = null; _verificationId = null; });
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneCtrl.text.trim(),
        timeout: const Duration(seconds: 60),
        verificationCompleted: _onAutoSignIn,
        verificationFailed: (e) {
          if (!mounted) return;
          setState(() { _error = e.message ?? 'Verification failed'; _loading = false; });
        },
        codeSent: (verificationId, _) {
          if (!mounted) return;
          setState(() { _verificationId = verificationId; _sentOtp = true; _loading = false; });
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _otpFocusNode.requestFocus();
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Cannot reach server. Check your connection.'; _loading = false; });
    }
  }

  Future<void> _register() async {
    if (_verificationId == null) return;
    HapticFeedback.lightImpact();
    setState(() { _loading = true; _error = null; });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpCtrl.text.trim(),
      );
      await _handleFirebaseCredential(credential);
    } catch (e) {
      HapticFeedback.vibrate();
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: tt.headlineSmall
          ?.copyWith(fontWeight: FontWeight.w700, color: cs.primary),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.transparent),
      ),
    );

        return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScaleTransition(
                  scale: _iconScale,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child:
                        Icon(Icons.business_rounded, size: 48, color: cs.secondary),
                  ),
                ),
                const SizedBox(height: 32),
                Text('Get Started',
                    style: tt.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800, letterSpacing: -1.0)),
                const SizedBox(height: 8),
                Text('Create an owner account to set up your factory floor.',
                    style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 40),
                AnimatedSize(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.fastOutSlowIn,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedOpacity(
                        opacity: _sentOtp ? 0.5 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: IgnorePointer(
                          ignoring: _sentOtp,
                          child: Column(
                            children: [
                              ValidatedField(
                                controller: _nameCtrl,
                                label: 'Your Name',
                                prefixIcon: Icons.person_rounded,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Enter your name';
                                  if (v.trim().length < 2) return 'Name is too short';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              ValidatedField(
                                controller: _phoneCtrl,
                                label: 'Phone Number',
                                prefixIcon: Icons.phone_rounded,
                                keyboardType: TextInputType.phone,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty || v.trim() == '+91') return 'Enter a valid phone number';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              ValidatedField(
                                controller: _factoryCtrl,
                                label: 'Factory Name',
                                prefixIcon: Icons.domain_rounded,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Enter your factory name';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_sentOtp) ...[
                        const SizedBox(height: 32),
                        Divider(color: cs.outlineVariant),
                        const SizedBox(height: 24),
                        Text('Verify Your Number',
                            style: tt.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                            'We sent a 6-digit code to ${_phoneCtrl.text}',
                            style: tt.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant)),
                        const SizedBox(height: 24),
                        Center(
                          child: Pinput(
                            controller: _otpCtrl,
                            focusNode: _otpFocusNode,
                            length: 6,
                            defaultPinTheme: defaultPinTheme,
                            focusedPinTheme: defaultPinTheme.copyWith(
                              decoration: defaultPinTheme.decoration?.copyWith(
                                border:
                                    Border.all(color: cs.primary, width: 2),
                                color: cs.surface,
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          cs.primary.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      spreadRadius: 2)
                                ],
                              ),
                            ),
                            onCompleted: (pin) => _register(),
                          ),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: cs.errorContainer.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline_rounded,
                                  color: cs.onErrorContainer),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(_error!,
                                    style: tt.bodyMedium?.copyWith(
                                        color: cs.onErrorContainer,
                                        fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                FilledButton(
                  onPressed:
                      _loading ? null : (_sentOtp ? _register : _requestOtp),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(60),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 3, color: Colors.white))
                      : Text(
                          _sentOtp ? 'Create Account' : 'Continue',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
