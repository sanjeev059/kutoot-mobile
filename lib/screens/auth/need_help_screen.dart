import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'support_submitted_screen.dart';

class NeedHelpScreen extends StatefulWidget {
  final String? phoneHint;

  const NeedHelpScreen({super.key, this.phoneHint});

  @override
  State<NeedHelpScreen> createState() => _NeedHelpScreenState();
}

class _NeedHelpScreenState extends State<NeedHelpScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.phoneHint != null && widget.phoneHint!.isNotEmpty) {
      _mobileController.text = '+91 ${widget.phoneHint}';
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SupportSubmittedScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
        ),
        title: Image.asset(
          AppTheme.logoAsset,
          width: 34,
          height: 34,
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                'Need Help?',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: 80,
            left: 12,
            child: Icon(Icons.home_work_outlined,
                size: 56, color: AppTheme.neutral.withValues(alpha: 0.06)),
          ),
          Positioned(
            top: 120,
            right: 16,
            child: Icon(Icons.payments_outlined,
                size: 56, color: AppTheme.neutral.withValues(alpha: 0.06)),
          ),
          Positioned(
            bottom: 120,
            left: 28,
            child: Icon(Icons.two_wheeler_outlined,
                size: 74, color: AppTheme.neutral.withValues(alpha: 0.06)),
          ),
          Positioned(
            bottom: 96,
            right: 22,
            child: Icon(Icons.phone_android_outlined,
                size: 52, color: AppTheme.neutral.withValues(alpha: 0.06)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 24),
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [
                        AppTheme.primary,
                        AppTheme.secondaryContainer
                      ]),
                    ),
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.help_center_rounded,
                          color: AppTheme.primary, size: 46),
                    ),
                  ),
                  const Text(
                    'Need Help?',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Fill out the form below and our team will\nget back to you shortly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Mobile Number',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _mobileController,
                    decoration: InputDecoration(
                      hintText: '+966 50 XXX XXXX',
                      fillColor: const Color(0xFFF5E5DB),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Description',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    minLines: 4,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Tell us what you need help with...',
                      fillColor: const Color(0xFFF5E5DB),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  InkWell(
                    onTap: _submit,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTheme.primary, AppTheme.primaryContainer],
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Submit Request',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.send, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Back to Verification',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
