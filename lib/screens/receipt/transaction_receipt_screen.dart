import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

class TransactionReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionReceiptScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final amount = transaction['amount'] ?? 128.50;
    final date = transaction['created_at'] ?? 'Oct 26, 2023';
    final storeName = transaction['store_name'] ??
        transaction['description'] ??
        'Kutoot Store';
    final stamps = transaction['stamps_earned'] ?? 12;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Transaction Receipt',
            style: TextStyle(
                color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        foregroundColor: AppTheme.textPrimary,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Successful',
                style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06), blurRadius: 16)
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.store_rounded,
                        color: AppTheme.primary, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(storeName.toString(),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('\$$amount',
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary)),
                  const SizedBox(height: 24),
                  _ReceiptRow('Date', date.toString()),
                  _ReceiptRow('Time', '02:45 PM'),
                  _ReceiptRow(
                      'Transaction ID',
                      transaction['id']?.toString() ??
                          'TXN${DateTime.now().millisecondsSinceEpoch}'),
                  _ReceiptRow('Payment Method', 'Visa ending in 4242'),
                  const Divider(height: 24),
                  _ReceiptRow('Subtotal', '\$${amount}'),
                  _ReceiptRow('Discount', '-\$0.00'),
                  _ReceiptRow('Total Paid', '\$$amount', bold: true),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('REWARDS EARNED: $stamps Loyalty Stamps',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                            fontSize: 14)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showComingSoon(context),
                child: const Text('Download Receipt'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showComingSoon(context),
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary),
                child: const Text('Repeat Purchase'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Coming soon')));
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _ReceiptRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
