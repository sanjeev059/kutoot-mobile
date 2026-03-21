import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PaymentMethodsScreen extends StatefulWidget {
  final double amount;

  const PaymentMethodsScreen({super.key, this.amount = 1000.00});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedCard = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Payment', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        foregroundColor: AppTheme.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Saved'),
            Tab(text: 'New'),
            Tab(text: 'UPI'),
            Tab(text: 'Net Banking'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SavedCardsTab(selectedCard: _selectedCard, onSelect: (i) => setState(() => _selectedCard = i)),
          const Center(child: Text('Add new card')),
          _UpiTab(),
          const Center(child: Text('Select your bank')),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Payable', style: TextStyle(fontSize: 16)),
                Text('₹${widget.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment initiated'))),
                child: const Text('Proceed to Pay'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedCardsTab extends StatelessWidget {
  final int selectedCard;
  final ValueChanged<int> onSelect;

  const _SavedCardsTab({required this.selectedCard, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _CardTile(
          last4: '4242',
          brand: 'Visa',
          isSelected: selectedCard == 0,
          onTap: () => onSelect(0),
        ),
        const SizedBox(height: 12),
        _CardTile(
          last4: '8888',
          brand: 'Mastercard',
          isSelected: selectedCard == 1,
          onTap: () => onSelect(1),
        ),
      ],
    );
  }
}

class _CardTile extends StatelessWidget {
  final String last4;
  final String brand;
  final bool isSelected;
  final VoidCallback onTap;

  const _CardTile({required this.last4, required this.brand, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? AppTheme.primary : Colors.transparent, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.credit_card_rounded, color: AppTheme.primary, size: 40),
        title: Text('$brand **** $last4', style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primary) : null,
      ),
    );
  }
}

class _UpiTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _UpiOption(icon: Icons.phone_android, name: 'PhonePe', onTap: () {}),
        const SizedBox(height: 12),
        _UpiOption(icon: Icons.payment, name: 'Google Pay', onTap: () {}),
      ],
    );
  }
}

class _UpiOption extends StatelessWidget {
  final IconData icon;
  final String name;
  final VoidCallback onTap;

  const _UpiOption({required this.icon, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppTheme.primary),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
