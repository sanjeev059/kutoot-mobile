import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'otp_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Consumer<AuthProvider>(
            builder: (context, auth, _) => _LoginForm(auth: auth),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  final AuthProvider auth;

  const _LoginForm({required this.auth});

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String _countryCode = '+91';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _identifier {
    final input = _controller.text.trim();
    if (input.contains('@')) return input;
    return input.replaceAll(RegExp(r'\D'), '');
  }

  Future<void> _sendOtp() async {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter phone number or email')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final identifier = _identifier;
    final (ok, debugOtp) = await widget.auth.sendOtp(identifier);
    setState(() => _isLoading = false);

    if (ok && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(identifier: identifier, debugOtp: debugOtp),
        ),
      );
    } else if (widget.auth.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.auth.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(flex: 2),
        Text(
          'Log in or Sign up',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: onSurface,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your mobile number',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: onSurface.withOpacity(0.7),
              ),
        ),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0).withOpacity(0.6)),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _countryCode,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, size: 20, color: onSurface.withOpacity(0.7)),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFE0E0E0).withOpacity(0.7)),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d@.a-zA-Z]')),
                  ],
                  style: TextStyle(color: onSurface),
                  decoration: InputDecoration(
                    hintText: 'Phone number or email',
                    hintStyle: TextStyle(color: onSurface.withOpacity(0.55)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading || widget.auth.isLoading ? null : _sendOtp,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            ),
            child: _isLoading || widget.auth.isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Next'),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'By continuing, you agree to our Terms of Service and Privacy Policy',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: onSurface.withOpacity(0.7),
                fontSize: 12,
              ),
        ),
        const Spacer(flex: 3),
      ],
    );
  }
}
