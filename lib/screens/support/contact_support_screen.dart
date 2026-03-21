import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'submit_ticket_screen.dart';
import 'my_tickets_screen.dart';

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      (Icons.payment_rounded, 'Payment'),
      (Icons.card_giftcard_rounded, 'Rewards'),
      (Icons.account_balance_wallet_rounded, 'Wallet'),
      (Icons.store_rounded, 'Stores'),
      (Icons.settings_rounded, 'Account'),
    ];

    final questions = [
      ('How do I earn stamps?', 'Make purchases at participating stores. You earn 1 stamp per ₹100 spent.'),
      ('How do I redeem rewards?', 'Go to Rewards, browse available rewards, and tap Redeem. Show your code at the store.'),
      ('Where is my transaction history?', 'Go to Profile > Transaction History or Wallet to view all transactions.'),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Help & Support', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        foregroundColor: AppTheme.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Help Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: categories.map((c) => _CategoryChip(icon: c.$1, label: c.$2, onTap: () {})).toList(),
            ),
            const SizedBox(height: 24),
            const Text('Support Channels', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showComingSoon(context),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('Chat with Us'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showComingSoon(context),
              icon: const Icon(Icons.email_outlined),
              label: const Text('Email Support'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 0),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showComingSoon(context),
              icon: const Icon(Icons.phone_outlined),
              label: const Text('Call Us'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 0),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('My Tickets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTicketsScreen())),
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Common Questions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...questions.map((q) => _QuestionTile(question: q.$1, answer: q.$2)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubmitTicketScreen())),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Submit a Ticket'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon')));
  }
}

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CategoryChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.primary, size: 24),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _QuestionTile extends StatefulWidget {
  final String question;
  final String answer;

  const _QuestionTile({required this.question, required this.answer});

  @override
  State<_QuestionTile> createState() => _QuestionTileState();
}

class _QuestionTileState extends State<_QuestionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(widget.question, style: const TextStyle(fontWeight: FontWeight.w500)),
            trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(widget.answer, style: const TextStyle(color: AppTheme.textSecondary, height: 1.5)),
            ),
        ],
      ),
    );
  }
}
