import 'package:flutter/material.dart';
import '../../api/kutoot_api.dart';
import '../../theme/app_theme.dart';
import '../receipt/transaction_receipt_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _api = KutootApi();
  List<dynamic> _transactions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.getTransactions();
      final data = res.data;
      if (data is Map && data['data'] != null) {
        _transactions = data['data'] is List ? data['data'] as List : [];
      } else if (data is List) {
        _transactions = data;
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Transactions',
            style: TextStyle(
                color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        foregroundColor: AppTheme.textPrimary,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _transactions.isEmpty
                  ? const Center(child: Text('No transactions yet'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _transactions.length,
                        itemBuilder: (context, i) {
                          final t = _transactions[i] is Map
                              ? _transactions[i] as Map
                              : {};
                          final type = t['type'] ?? t['transaction_type'] ?? '';
                          final amount = t['amount'] ?? t['value'] ?? '';
                          final desc = t['description'] ?? t['reason'] ?? '';
                          final date = t['created_at'] ?? t['date'] ?? '';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 12)
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.receipt_long_rounded,
                                    color: AppTheme.primary, size: 24),
                              ),
                              title: Text(
                                  desc.toString().isNotEmpty
                                      ? desc.toString()
                                      : type.toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: date.toString().isNotEmpty
                                  ? Text(date.toString())
                                  : null,
                              trailing: amount.toString().isNotEmpty
                                  ? Text('₹$amount',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600))
                                  : null,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TransactionReceiptScreen(
                                      transaction:
                                          Map<String, dynamic>.from(t)),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
