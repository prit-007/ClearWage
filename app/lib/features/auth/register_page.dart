import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:pinput/pinput.dart';
import '../../core/token_storage.dart';
import '../../core/widgets/firebase_phone_field.dart';
import '../../core/widgets/validated_field.dart';
import '../../models/auth_model.dart';
import '../../providers/providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _factoryCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _otpFocusNode = FocusNode();

  bool _sentOtp = false;
  bool _loading = false;
  String? _error;
  String? _verificationId;

  // Countdown timer for OTP resend
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;

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
    _timer?.cancel();
    _iconAnim.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _factoryCtrl.dispose();
    _otpCtrl.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
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
      TokenStorage.save(token.token);
      final userInfo = AppUser.fromAuthToken(token);
      TokenStorage.saveUserInfo(userInfo);
      ref.read(userInfoProvider.notifier).state = userInfo;
      HapticFeedback.heavyImpact();
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/onboarding', (_) => false);
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.vibrate();
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _requestOtp() async {
    HapticFeedback.mediumImpact();
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your full name');
      return;
    }
    if (_factoryCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your factory name');
      return;
    }
    final raw = _phoneCtrl.text.trim();
    if (raw.isEmpty || raw.length != 10) {
      setState(() => _error = 'Please enter a valid 10-digit phone number');
      return;
    }
    final phone = '+91$raw';

    setState(() { _loading = true; _error = null; _verificationId = null; });
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: _onAutoSignIn,
        verificationFailed: (e) {
          if (!mounted) return;
          HapticFeedback.vibrate();
          setState(() { _error = e.message ?? 'Verification failed'; _loading = false; });
        },
        codeSent: (verificationId, _) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _sentOtp = true;
            _loading = false;
          });
          _startResendTimer();
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
      HapticFeedback.vibrate();
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
      setState(() { _error = 'Invalid verification code. Please try again.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final defaultPinTheme = PinTheme(
      width: 52,
      height: 58,
      textStyle: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: cs.primary),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
    );

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft, color: cs.onSurface),
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScaleTransition(
                  scale: _iconScale,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.secondary.withValues(alpha: 0.2), width: 2),
                    ),
                    child: Icon(PhosphorIconsFill.buildings, size: 44, color: cs.secondary),
                  ),
                ),
                const SizedBox(height: 32),
                Text('Get Started',
                    style: tt.displaySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1.0)),
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
                      // Form Fields Phase
                      AnimatedOpacity(
                        opacity: _sentOtp ? 0.5 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: IgnorePointer(
                          ignoring: _sentOtp,
                          child: Column(
                            children: [
                              ValidatedField(
                                controller: _nameCtrl,
                                label: 'Your Full Name',
                                prefixIcon: PhosphorIconsRegular.user,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Enter your name';
                                  if (v.trim().length < 2) return 'Name is too short';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              FirebasePhoneField(
                                controller: _phoneCtrl,
                                label: 'Mobile Number',
                              ),
                              const SizedBox(height: 16),
                              ValidatedField(
                                controller: _factoryCtrl,
                                label: 'Factory / Business Name',
                                prefixIcon: PhosphorIconsRegular.buildings,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Enter your factory name';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // OTP Verification Phase
                      if (_sentOtp) ...[
                        const SizedBox(height: 32),
                        Divider(color: cs.outlineVariant.withValues(alpha: 0.5)),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('SECURITY CODE',
                                style: tt.labelSmall?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                )),
                            TextButton(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _sentOtp = false;
                                  _otpCtrl.clear();
                                  _error = null;
                                });
                              },
                              child: const Text('Edit Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('We sent a 6-digit verification code to +91${_phoneCtrl.text}',
                            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                        const SizedBox(height: 24),
                        Center(
                          child: Pinput(
                            controller: _otpCtrl,
                            focusNode: _otpFocusNode,
                            length: 6,
                            defaultPinTheme: defaultPinTheme,
                            focusedPinTheme: defaultPinTheme.copyWith(
                              decoration: defaultPinTheme.decoration?.copyWith(
                                border: Border.all(color: cs.primary, width: 2),
                                color: cs.surface,
                                boxShadow: [
                                  BoxShadow(
                                      color: cs.primary.withValues(alpha: 0.15),
                                      blurRadius: 12,
                                      spreadRadius: 2)
                                ],
                              ),
                            ),
                            onCompleted: (pin) => _register(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Resend Counter
                        Center(
                          child: _canResend
                              ? TextButton.icon(
                                  onPressed: _loading ? null : _requestOtp,
                                  icon: Icon(PhosphorIconsRegular.arrowsClockwise, size: 16, color: cs.primary),
                                  label: Text('Resend Code', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold)),
                                )
                              : Text(
                                  'Resend code in $_secondsRemaining',
                                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
                                ),
                        ),
                      ],

                      // Error Alert Box
                      if (_error != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.errorContainer.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: cs.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(PhosphorIconsFill.warningCircle, color: cs.onErrorContainer, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: tt.bodyMedium?.copyWith(
                                    color: cs.onErrorContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
                  onPressed: _loading ? null : (_sentOtp ? _register : _requestOtp),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                      : Text(
                          _sentOtp ? 'Complete Account Setup' : 'Send Verification Code',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}