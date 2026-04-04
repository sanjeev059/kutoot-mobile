import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'legal_loading_screen.dart';
import 'need_help_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _mobileController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  String get _digits => _mobileController.text.replaceAll(RegExp(r'\D'), '');
  bool get _validPhone => _digits.length == 10;
  String get _otp => _otpControllers.map((e) => e.text).join();
  bool get _validOtp => _otp.length == 6;

  bool _sending = false;
  bool _otpSent = false;
  bool _verifying = false;
  int _seconds = 0;
  Timer? _timer;
  String? _debugOtp;

  late final AnimationController _bgAnim;

  @override
  void initState() {
    super.initState();
    _bgAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mobileController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _bgAnim.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_seconds == 0) {
        timer.cancel();
        return;
      }
      setState(() => _seconds--);
    });
  }

  Future<void> _sendOtp() async {
    if (!_validPhone || _sending) return;
    setState(() => _sending = true);

    final auth = context.read<AuthProvider>();
    final (success, debugOtp) = await auth.sendOtp(_digits);

    if (!mounted) return;
    setState(() => _sending = false);

    if (success) {
      setState(() {
        _otpSent = true;
        _debugOtp = debugOtp;
      });
      _startTimer();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _otpFocusNodes.first.requestFocus();
      });
      if (debugOtp != null && debugOtp.length == 6) {
        _autoFillOtp(debugOtp);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Failed to send OTP'),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }

  void _autoFillOtp(String otp) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      for (var i = 0; i < 6 && i < otp.length; i++) {
        _otpControllers[i].text = otp[i];
      }
      setState(() {});
      _autoVerify();
    });
  }

  void _onOtpChanged(int index, String value) {
    if (value.length > 1) {
      _otpControllers[index].text = value.characters.last;
      _otpControllers[index].selection =
          const TextSelection.collapsed(offset: 1);
      value = _otpControllers[index].text;
    }
    if (value.isNotEmpty && index < _otpFocusNodes.length - 1) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
    setState(() {});

    if (_validOtp) {
      _autoVerify();
    }
  }

  Future<void> _autoVerify() async {
    if (!_validOtp || _verifying) return;
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted || !_validOtp) return;
    _verify();
  }

  Future<void> _verify() async {
    if (!_validOtp || _verifying) return;
    setState(() => _verifying = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOtp(_digits, _otp);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LegalLoadingScreen()),
      );
    } else {
      setState(() => _verifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Invalid or expired OTP'),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }

  Future<void> _resend() async {
    if (_seconds != 0) return;
    for (final c in _otpControllers) {
      c.clear();
    }
    _otpFocusNodes.first.requestFocus();

    final auth = context.read<AuthProvider>();
    final (success, debugOtp) = await auth.sendOtp(_digits);
    if (!mounted) return;
    if (success) {
      _startTimer();
      if (debugOtp != null && debugOtp.length == 6) {
        _debugOtp = debugOtp;
        _autoFillOtp(debugOtp);
      }
    }
  }

  void _onPhoneChanged(String _) {
    setState(() {});
    if (_validPhone && !_otpSent && !_sending) {
      _sendOtp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          // Animated background circles
          AnimatedBuilder(
            animation: _bgAnim,
            builder: (_, __) => Stack(
              children: [
                Positioned(
                  top: -80 + (_bgAnim.value * 30),
                  right: -60 + (_bgAnim.value * 20),
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.primary.withValues(alpha: 0.08),
                          AppTheme.primary.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -60 - (_bgAnim.value * 20),
                  left: -40 + (_bgAnim.value * 15),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.secondary.withValues(alpha: 0.08),
                          AppTheme.secondary.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.4,
                  left: MediaQuery.of(context).size.width * 0.6,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFD700)
                          .withValues(alpha: 0.04 + _bgAnim.value * 0.03),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Row(
                    children: [
                      if (Navigator.of(context).canPop())
                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: AppTheme.textPrimary),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      Image.asset('assets/images/k_logo.png',
                          width: 32, height: 32, fit: BoxFit.contain),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        // Logo without white background
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primary.withValues(alpha: 0.08),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Image.asset('assets/images/k_logo.png',
                                fit: BoxFit.contain),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _otpSent ? 'Verify OTP' : 'Welcome',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _otpSent
                              ? 'Code sent to +91 $_digits'
                              : 'Future of local commerce',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Phone input
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Text('MOBILE NUMBER',
                                style: TextStyle(
                                    color: Color(0xFF8D7072),
                                    letterSpacing: 1.2,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 58,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5E5DB),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 14),
                              const Text('+91',
                                  style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(width: 10),
                              Container(
                                  width: 1,
                                  height: 28,
                                  color: const Color(0xFFE1BEC0)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _mobileController,
                                  keyboardType: TextInputType.phone,
                                  onChanged: _onPhoneChanged,
                                  enabled: !_otpSent,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18),
                                  decoration: const InputDecoration(
                                    hintText: '00000 00000',
                                    hintStyle: TextStyle(
                                        color: Color(0x99594042),
                                        fontWeight: FontWeight.w700),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              if (_otpSent)
                                GestureDetector(
                                  onTap: () => setState(() {
                                    _otpSent = false;
                                    _timer?.cancel();
                                    for (final c in _otpControllers) {
                                      c.clear();
                                    }
                                  }),
                                  child: const Padding(
                                    padding: EdgeInsets.only(right: 6),
                                    child: Text('Edit',
                                        style: TextStyle(
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13)),
                                  ),
                                ),
                              if (!_otpSent && _validPhone)
                                GestureDetector(
                                  onTap: _sendOtp,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: _sending
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppTheme.primary))
                                        : const Text('Send OTP',
                                            style: TextStyle(
                                                color: AppTheme.primary,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13)),
                                  ),
                                ),
                              if (!_otpSent && !_validPhone)
                                Icon(Icons.check_circle,
                                    color: const Color(0x80AE1E3F)),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),

                        // OTP Section
                        if (_otpSent) ...[
                          const SizedBox(height: 24),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Text('ENTER OTP',
                                  style: TextStyle(
                                      color: Color(0xFF8D7072),
                                      letterSpacing: 1.2,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(6, (i) {
                              return SizedBox(
                                width: 48,
                                height: 56,
                                child: TextField(
                                  controller: _otpControllers[i],
                                  focusNode: _otpFocusNodes[i],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  onChanged: (v) => _onOtpChanged(i, v),
                                  style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800),
                                  decoration: InputDecoration(
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 14),
                                    filled: true,
                                    fillColor: const Color(0xFFF5E5DB),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color:
                                            AppTheme.primary.withValues(alpha: 0.25),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Didn't receive? ",
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13)),
                              GestureDetector(
                                onTap: _resend,
                                child: Text(
                                  'Resend OTP',
                                  style: TextStyle(
                                    color: _seconds == 0
                                        ? AppTheme.primary
                                        : AppTheme.primary.withValues(alpha: 0.5),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (_seconds > 0)
                                Text(
                                    ' in 0:${_seconds.toString().padLeft(2, '0')}s',
                                    style: const TextStyle(
                                        color: Color(0x99594042), fontSize: 13)),
                            ],
                          ),
                          if (_verifying) ...[
                            const SizedBox(height: 20),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: AppTheme.primary)),
                                SizedBox(width: 10),
                                Text('Verifying...',
                                    style: TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15)),
                              ],
                            ),
                          ],
                        ],

                        const SizedBox(height: 20),

                        // T&C text with clickable links
                        Text.rich(
                          TextSpan(
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                height: 1.4),
                            children: [
                              const TextSpan(
                                  text: 'By continuing, you agree to our '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () => _showTermsDialog(
                                      context, 'Terms of Service'),
                                  child: const Text('Terms of Service',
                                      style: TextStyle(
                                          color: AppTheme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          decoration:
                                              TextDecoration.underline)),
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () => _showTermsDialog(
                                      context, 'Privacy Policy'),
                                  child: const Text('Privacy Policy',
                                      style: TextStyle(
                                          color: AppTheme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          decoration:
                                              TextDecoration.underline)),
                                ),
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  NeedHelpScreen(phoneHint: _digits),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.contact_support_outlined,
                                    size: 16, color: AppTheme.primary),
                                SizedBox(width: 4),
                                Text('Need Help?',
                                    style: TextStyle(
                                        color: AppTheme.primary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 18)),
        content: SizedBox(
          height: 300,
          child: SingleChildScrollView(
            child: Text(
              title == 'Terms of Service'
                  ? 'By using Kutoot, you agree to these terms:\n\n'
                      '1. You must be 18+ to create an account.\n'
                      '2. One account per device and mobile number.\n'
                      '3. Rewards and coupons are non-transferable.\n'
                      '4. Kutoot reserves the right to modify or terminate rewards programs.\n'
                      '5. Any fraudulent activity will result in account suspension.\n'
                      '6. Users are responsible for maintaining account security.\n'
                      '7. Kutoot is not liable for merchant products or services.\n\n'
                      'For full terms, visit kutoot.com/terms'
                  : 'Kutoot Privacy Policy:\n\n'
                      '1. We collect your phone number, location, and transaction data.\n'
                      '2. Your data is used to provide personalized offers and rewards.\n'
                      '3. We do not sell your personal information to third parties.\n'
                      '4. Location data helps us show nearby stores and offers.\n'
                      '5. You can request account deletion at any time.\n'
                      '6. We use industry-standard encryption to protect your data.\n\n'
                      'For full policy, visit kutoot.com/privacy',
              style: const TextStyle(
                  fontSize: 14, height: 1.5, color: AppTheme.textSecondary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close',
                style: TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
