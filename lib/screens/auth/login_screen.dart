import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'need_help_screen.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _logoAsset = 'assets/images/k_logo.png';
  static const String _foodUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuC06zacuaFHV7P-wH411KFYqyKJLIK0XTTeAP70OfLWmymHrVRqEho2VwUnxu-YmebUZ6JL7TjRvtZKOciLBQxYoIpQSbhZTUSS3DPjqUMiRR2BlqWNHqpWQSGEfaPI7ONZpThLHdM08wgJVC5X8bPg9JHy9os-qRvLTV7IBad7zfsX5FkOgV_dIfN9dDlphX7MQwsMWAPkHyFsa28eLv5RfTb59hu8IUJIEx0CnEGXHm_IilrRBycwlH1MEv_nDW5ky4im2vCWiw';
  static const String _storeUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBqkzOJPr5UReWxGrO2BEWCe3xlo3mvrfsq8iHPYHw7dXg5Y9p0plNjKz3nWvVj5wSOHMyow74dzd_wBD1_539E6nH0zloIxyI8HQb4brpaAzFHpuvpw8I5qM-itOTIIdPnctJM12I0tHkwDb50QN1skba1AwF4S4df5xUaQVBdSYmexjdZU-RhhIOjj-kTSeSqPkCZMW4h4-EfGc9QASpdoCk0nsW8ayqpcoJ73qisTL5Go1ClurvKZo72UidlkwqVLP16O72kZQ';

  final TextEditingController _mobileController = TextEditingController();
  bool _sending = false;

  String get _digits => _mobileController.text.replaceAll(RegExp(r'\D'), '');
  bool get _valid => _digits.length == 10;

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_valid || _sending) return;
    setState(() => _sending = true);
    final auth = context.read<AuthProvider>();
    final (success, debugOtp) = await auth.sendOtp(_digits);
    if (!mounted) return;
    setState(() => _sending = false);
    if (success) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OtpScreen(phoneNumber: _digits, debugOtp: debugOtp)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Failed to send OTP')),
      );
      auth.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                children: [
                  Image.asset(
                    _logoAsset,
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Kutoot',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 132,
                          height: 132,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primary.withValues(alpha: 0.10),
                          ),
                        ),
                        Container(
                          width: 118,
                          height: 118,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Image.asset(_logoAsset, fit: BoxFit.contain),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'Welcome',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Future of local commerce',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text(
                          'MOBILE NUMBER',
                          style: TextStyle(
                            color: Color(0xFF8D7072),
                            letterSpacing: 1.2,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5E5DB),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          const Text(
                            '+91',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                              width: 1,
                              height: 30,
                              color: const Color(0xFFE1BEC0)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _mobileController,
                              keyboardType: TextInputType.phone,
                              onChanged: (_) => setState(() {}),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              ),
                              decoration: const InputDecoration(
                                hintText: '00000 00000',
                                hintStyle: TextStyle(
                                    color: Color(0x99594042),
                                    fontWeight: FontWeight.w700),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.check_circle,
                            color: _valid
                                ? AppTheme.primary
                                : const Color(0x80AE1E3F),
                          ),
                          const SizedBox(width: 14),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    InkWell(
                      onTap: _valid && !_sending ? _continue : null,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 58,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _valid && !_sending
                                ? const [
                                    AppTheme.primary,
                                    AppTheme.primaryContainer
                                  ]
                                : const [Color(0xFFA97A86), Color(0xFFB58A94)],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_sending)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            else ...[
                              const Text(
                                'Log In',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, color: Colors.white),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'By continuing, you agree to our Terms of Service and Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NeedHelpScreen(phoneHint: _digits),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.contact_support_outlined,
                                size: 16, color: AppTheme.primary),
                            SizedBox(width: 4),
                            Text(
                              'Need Help?',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _EditorialTile(
                              label: 'Fresh Delivery', imageUrl: _foodUrl),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Transform.translate(
                            offset: const Offset(0, 14),
                            child: _EditorialTile(
                                label: 'Local Shops', imageUrl: _storeUrl),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorialTile extends StatelessWidget {
  final String label;
  final String imageUrl;

  const _EditorialTile({required this.label, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 128,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(imageUrl, fit: BoxFit.cover),
            Container(
                color: AppTheme.surfaceContainerLow.withValues(alpha: 0.66)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x99FFF1E8)],
                ),
              ),
            ),
            Positioned(
              left: 10,
              bottom: 10,
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
