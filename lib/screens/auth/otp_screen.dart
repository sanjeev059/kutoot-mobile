import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';

class OtpScreen extends StatelessWidget {
  final String identifier;
  final String? debugOtp;

  const OtpScreen({super.key, required this.identifier, this.debugOtp});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _OtpForm(identifier: identifier, debugOtp: debugOtp),
        ),
      ),
    );
  }
}

class _OtpForm extends StatefulWidget {
  final String identifier;
  final String? debugOtp;

  const _OtpForm({required this.identifier, this.debugOtp});

  @override
  State<_OtpForm> createState() => _OtpFormState();
}

class _OtpFormState extends State<_OtpForm> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  int _resendSeconds = 0;
  String? _currentDebugOtp;

  @override
  void initState() {
    super.initState();
    _resendSeconds = 60;
    _currentDebugOtp = widget.debugOtp;
    final debug = widget.debugOtp;
    if (debug != null && debug.length == 6) {
      for (var i = 0; i < 6; i++) {
        _controllers[i].text = debug[i];
      }
    }
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      _startResendTimer();
    });
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendSeconds = (_resendSeconds - 1).clamp(0, 60));
      return _resendSeconds > 0;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit code')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final ok = await context.read<AuthProvider>().verifyOtp(widget.identifier, _otp);
    setState(() => _isLoading = false);

    if (ok && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<AuthProvider>().error ?? 'Invalid OTP')),
      );
    }
  }

  Future<void> _resendOtp() async {
    if (_resendSeconds > 0) return;
    final (ok, debugOtp) = await context.read<AuthProvider>().sendOtp(widget.identifier);
    if (mounted) {
      for (final c in _controllers) c.clear();
      if (ok && debugOtp != null && debugOtp.length == 6) {
        setState(() => _currentDebugOtp = debugOtp);
        for (var i = 0; i < 6; i++) {
          _controllers[i].text = debugOtp[i];
        }
      } else {
        setState(() => _currentDebugOtp = null);
      }
      _focusNodes.first.requestFocus();
      setState(() => _resendSeconds = 60);
      _startResendTimer();
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      _controllers[index].text = value[value.length - 1];
    }
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Verify your phone number',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: onSurface,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the 6-digit code sent to ${widget.identifier}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: onSurface.withOpacity(0.7),
              ),
        ),
        if ((_currentDebugOtp ?? widget.debugOtp) != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.developer_mode, size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Dev OTP: ${_currentDebugOtp ?? widget.debugOtp}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            return SizedBox(
              width: 48,
              child: TextField(
                controller: _controllers[i],
                focusNode: _focusNodes[i],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(color: onSurface),
                onChanged: (v) => _onDigitChanged(i, v),
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _resendSeconds == 0 ? _resendOtp : null,
          child: Text(
            _resendSeconds > 0 ? 'Resend OTP in ${_resendSeconds}s' : 'Resend OTP',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _resendSeconds == 0 ? AppTheme.primary : onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading || _otp.length != 6 ? null : _verify,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [Text('Verify '), Icon(Icons.arrow_forward_rounded, size: 20)],
                  ),
          ),
        ),
      ],
    );
  }
}
