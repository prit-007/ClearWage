import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:pinput/pinput.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_config.dart';
import '../../core/token_storage.dart';
import '../../core/widgets/firebase_phone_field.dart';
import '../../data/models/auth_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/services.dart';
import '../../core/responsive.dart';
import 'register_page.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneCtrl = TextEditingController();
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

  late AnimationController _logoAnim;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _logoAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _logoScale = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _logoAnim, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _logoAnim.dispose();
    _phoneCtrl.dispose();
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  void _onAutoSignIn(PhoneAuthCredential credential) {
    _handleFirebaseCredential(credential, isLogin: true);
  }

  Future<void> _handleFirebaseCredential(
    PhoneAuthCredential credential, {
    required bool isLogin,
  }) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Failed to get Firebase user');
      final idToken = await user.getIdToken();
      if (idToken == null) throw Exception('Failed to get Firebase ID token');
      final token = await ref
          .read(authServiceProvider)
          .signInWithFirebase(idToken);
      ref.read(tokenProvider.notifier).state = token.token;
      unawaited(TokenStorage.save(token.token));
      final userInfo = AppUser.fromAuthToken(token);
      unawaited(TokenStorage.saveUserInfo(userInfo));
      ref.read(userInfoProvider.notifier).state = userInfo;
      unawaited(HapticFeedback.heavyImpact());
      if (mounted) context.go('/home');
    } catch (e) {
      if (!mounted) return;
      unawaited(HapticFeedback.vibrate());
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _requestOtp() async {
    unawaited(HapticFeedback.mediumImpact());
    final raw = _phoneCtrl.text.trim();
    if (raw.isEmpty || raw.length != 10) {
      setState(() => _error = 'Please enter a valid 10-digit phone number');
      return;
    }
    final phone = '+91$raw';
    setState(() {
      _loading = true;
      _error = null;
      _verificationId = null;
    });
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: _onAutoSignIn,
        verificationFailed: (e) {
          if (!mounted) return;
          HapticFeedback.vibrate();
          setState(() {
            _error = e.message ?? 'Verification failed';
            _loading = false;
          });
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
      unawaited(HapticFeedback.vibrate());
      setState(() {
        _error = 'Cannot reach server. Check your connection.';
        _loading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null) return;
    unawaited(HapticFeedback.lightImpact());
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpCtrl.text.trim(),
      );
      await _handleFirebaseCredential(credential, isLogin: true);
    } catch (e) {
      unawaited(HapticFeedback.vibrate());
      if (!mounted) return;
      setState(() {
        _error = 'Invalid verification code. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _showServerDialog() async {
    await showAdaptiveSheet<void>(
      context: context,
      builder: (_) =>
          _ServerConfigSheet(initialUrl: ref.read(serverUrlProvider)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final defaultPinTheme = PinTheme(
      width: 52,
      height: 58,
      textStyle: tt.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: cs.primary,
      ),
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
        actions: [
          IconButton(
            icon: Icon(PhosphorIconsRegular.gear, color: cs.onSurfaceVariant),
            onPressed: () {
              HapticFeedback.selectionClick();
              _showServerDialog();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: AppScrollPhysics.physics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScaleTransition(
                  scale: _logoScale,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      PhosphorIconsFill.factory,
                      size: 44,
                      color: cs.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  _getGreeting(),
                  style: tt.titleMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Workforce Portal',
                  style: tt.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _sentOtp
                      ? 'Enter the 6-digit code sent to +91${_phoneCtrl.text}'
                      : 'Enter your phone number to securely access your workspace.',
                  style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 40),

                AnimatedSize(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.fastOutSlowIn,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FirebasePhoneField(
                        controller: _phoneCtrl,
                        label: 'Mobile Number',
                        enabled: !_sentOtp,
                      ),

                      // OTP Code Section
                      if (_sentOtp) ...[
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'SECURITY CODE',
                              style: tt.labelSmall?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _sentOtp = false;
                                  _otpCtrl.clear();
                                  _error = null;
                                });
                              },
                              child: const Text(
                                'Change Phone',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Pinput(
                            controller: _otpCtrl,
                            focusNode: _otpFocusNode,
                            length: 6,
                            autofillHints: const [AutofillHints.oneTimeCode],
                            defaultPinTheme: defaultPinTheme,
                            focusedPinTheme: defaultPinTheme.copyWith(
                              decoration: defaultPinTheme.decoration?.copyWith(
                                border: Border.all(color: cs.primary, width: 2),
                                color: cs.surface,
                                boxShadow: [
                                  BoxShadow(
                                    color: cs.primary.withValues(alpha: 0.15),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            onCompleted: (pin) => _verifyOtp(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Resend OTP Counter
                        Center(
                          child: _canResend
                              ? TextButton.icon(
                                  onPressed: _loading ? null : _requestOtp,
                                  icon: Icon(
                                    PhosphorIconsRegular.arrowsClockwise,
                                    size: 16,
                                    color: cs.primary,
                                  ),
                                  label: Text(
                                    'Resend Code',
                                    style: TextStyle(
                                      color: cs.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Resend code in $_secondsRemaining',
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
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
                            border: Border.all(
                              color: cs.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIconsFill.warningCircle,
                                color: cs.onErrorContainer,
                                size: 22,
                              ),
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
                  onPressed: _loading
                      ? null
                      : (_sentOtp ? _verifyOtp : _requestOtp),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _sentOtp
                              ? 'Verify & Authenticate'
                              : 'Continue with Phone',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text(
                          'Create Account',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
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

class _ServerConfigSheet extends ConsumerStatefulWidget {
  final String initialUrl;

  const _ServerConfigSheet({required this.initialUrl});

  @override
  ConsumerState<_ServerConfigSheet> createState() => _ServerConfigSheetState();
}

class _ServerConfigSheetState extends ConsumerState<_ServerConfigSheet> {
  late final TextEditingController _urlCtrl = TextEditingController(
    text: widget.initialUrl,
  );

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 16,
        right: 16,
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(PhosphorIconsFill.gear, color: cs.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Server Configuration',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _urlCtrl,
                style: const TextStyle(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Server Address',
                  hintText: 'http://192.168.1.100:8081',
                  filled: true,
                  prefixIcon: Icon(
                    PhosphorIconsRegular.globe,
                    color: cs.onSurfaceVariant,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ref.read(serverUrlProvider.notifier).state = _urlCtrl.text
                      .trim();
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Save Configuration',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
