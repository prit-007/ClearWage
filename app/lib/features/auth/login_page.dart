import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import '../../core/app_config.dart';
import '../../core/widgets/validated_field.dart';
import '../../providers/providers.dart';
import 'register_page.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneCtrl = TextEditingController(text: '+91');
  final _otpCtrl = TextEditingController();
  final _otpFocusNode = FocusNode();

  bool _sentOtp = false;
  bool _loading = false;
  String? _error;
  String? _verificationId;

  late AnimationController _logoAnim;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _logoAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _logoScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _logoAnim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _logoAnim.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _otpFocusNode.dispose();
    super.dispose();
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

  Future<void> _handleFirebaseCredential(PhoneAuthCredential credential, {required bool isLogin}) async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Failed to get Firebase user');
      final idToken = await user.getIdToken();
      if (idToken == null) throw Exception('Failed to get Firebase ID token');
      final token = await ref.read(authServiceProvider).signInWithFirebase(idToken);
      ref.read(tokenProvider.notifier).state = token.token;
      HapticFeedback.heavyImpact();
      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _requestOtp() async {
    HapticFeedback.mediumImpact();
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty || phone == '+91') {
      setState(() => _error = 'Please enter a valid phone number');
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

  Future<void> _verifyOtp() async {
    if (_verificationId == null) return;
    HapticFeedback.lightImpact();
    setState(() { _loading = true; _error = null; });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpCtrl.text.trim(),
      );
      await _handleFirebaseCredential(credential, isLogin: true);
    } catch (e) {
      HapticFeedback.vibrate();
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _showServerDialog() {
    final urlCtrl = TextEditingController(text: ref.read(serverUrlProvider));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 16,
          right: 16,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Server Configuration',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: urlCtrl,
                decoration: InputDecoration(
                  labelText: 'Server Address',
                  hintText: 'http://192.168.1.100:8081',
                  filled: true,
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
                  HapticFeedback.selectionClick();
                  ref.read(serverUrlProvider.notifier).state =
                      urlCtrl.text.trim();
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Save Configuration'),
              ),
            ],
          ),
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
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: cs.onSurfaceVariant),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScaleTransition(
                  scale: _logoScale,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.factory_rounded, size: 48, color: cs.primary),
                  ),
                ),
                const SizedBox(height: 32),
                Text(_getGreeting(),
                    style: tt.titleMedium?.copyWith(
                        color: cs.primary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Sign In',
                    style: tt.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800, letterSpacing: -1.0)),
                const SizedBox(height: 8),
                Text('Enter your details to manage your workforce.',
                    style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 40),
                AnimatedSize(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.fastOutSlowIn,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      ValidatedField(
                        controller: _phoneCtrl,
                        label: 'Phone Number',
                        prefixIcon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                        enabled: !_sentOtp,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty || v.trim() == '+91') return 'Enter a valid phone number';
                          return null;
                        },
                      ),
                      if (_sentOtp) ...[
                        const SizedBox(height: 24),
                        Text('One-Time Password',
                            style: tt.labelLarge
                                ?.copyWith(color: cs.onSurfaceVariant)),
                        const SizedBox(height: 12),
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
                                      color: cs.primary.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      spreadRadius: 2)
                                ],
                              ),
                            ),
                            onCompleted: (pin) => _verifyOtp(),
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
                      _loading ? null : (_sentOtp ? _verifyOtp : _requestOtp),
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
                          _sentOtp ? 'Secure Login' : 'Continue',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5),
                        ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Don't have an account? ",
                          style: tt.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant)),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()),
                          );
                        },
                        style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8)),
                        child: const Text('Create Account',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
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
