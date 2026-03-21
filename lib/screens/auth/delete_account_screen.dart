import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'account_deleted_screen.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _lossRewards = false;
  bool _lossHistory = false;
  bool _lossBalance = false;
  bool _understand = false;

  bool get _canDelete => _lossRewards && _lossHistory && _lossBalance && _understand;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Delete Account', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        foregroundColor: AppTheme.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_rounded, color: Colors.red, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'Delete your account?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'You will lose the following:',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            _CheckTile(
              value: _lossRewards,
              onChanged: (v) => setState(() => _lossRewards = v),
              text: 'Loyalty Rewards',
            ),
            _CheckTile(
              value: _lossHistory,
              onChanged: (v) => setState(() => _lossHistory = v),
              text: 'Transaction History',
            ),
            _CheckTile(
              value: _lossBalance,
              onChanged: (v) => setState(() => _lossBalance = v),
              text: 'e-Gift Balance',
            ),
            const SizedBox(height: 24),
            _CheckTile(
              value: _understand,
              onChanged: (v) => setState(() => _understand = v),
              text: 'I understand that this action cannot be undone.',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canDelete
                    ? () async {
                        await context.read<AuthProvider>().logout();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const AccountDeletedScreen()),
                            (r) => false,
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: const Text('Delete Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String text;

  const _CheckTile({required this.value, required this.onChanged, required this.text});

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      title: Text(text),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppTheme.primary,
    );
  }
}
