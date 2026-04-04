import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  String _filter = 'Active';

  final List<_LootCard> _lootCards = const [
    _LootCard(
      title: '60% OFF',
      brand: 'Starbucks Reserve',
      code: 'SBUX60',
      status: _LootStatus.active,
      expiresIn: '3 days',
    ),
    _LootCard(
      title: '₹500 Cashback',
      brand: 'HDFC Bank',
      code: 'HDFC500',
      status: _LootStatus.active,
      expiresIn: '7 days',
    ),
    _LootCard(
      title: 'BOGO Deal',
      brand: 'Westside Fashion',
      code: 'WESTBOGO',
      status: _LootStatus.expiringSoon,
      expiresIn: '1 day',
    ),
    _LootCard(
      title: '15% OFF',
      brand: 'Nature\'s Basket',
      code: 'NB15',
      status: _LootStatus.used,
      expiresIn: null,
    ),
    _LootCard(
      title: '₹200 OFF',
      brand: 'Croma Electronics',
      code: 'CROMA200',
      status: _LootStatus.used,
      expiresIn: null,
    ),
  ];

  List<_LootCard> get _filteredCards {
    switch (_filter) {
      case 'Active':
        return _lootCards
            .where((c) =>
                c.status == _LootStatus.active ||
                c.status == _LootStatus.expiringSoon)
            .toList();
      case 'Used':
        return _lootCards.where((c) => c.status == _LootStatus.used).toList();
      case 'Expiring':
        return _lootCards
            .where((c) => c.status == _LootStatus.expiringSoon)
            .toList();
      default:
        return _lootCards;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = _filteredCards;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.92),
        elevation: 0,
        title: const Text(
          'My Loot',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        foregroundColor: AppTheme.textPrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: ['Active', 'Used', 'Expiring'].map((f) {
                final active = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: active ? AppTheme.primary : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: active
                              ? AppTheme.primary
                              : const Color(0xFFE1BEC0),
                        ),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          color: active ? Colors.white : AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: cards.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 56,
                            color: AppTheme.textSecondary.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'No loot here yet',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount: cards.length,
                    itemBuilder: (_, i) {
                      final card = cards[i];
                      final isExpiring =
                          card.status == _LootStatus.expiringSoon;
                      final isUsed = card.status == _LootStatus.used;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isUsed
                              ? const Color(0xFFF5F5F5)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isExpiring
                                ? const Color(0xFFE53935).withOpacity(0.4)
                                : const Color(0xFFE1BEC0)
                                    .withOpacity(isUsed ? 0.3 : 1),
                          ),
                          boxShadow: isUsed
                              ? []
                              : [
                                  BoxShadow(
                                    color: (isExpiring
                                            ? const Color(0xFFE53935)
                                            : Colors.black)
                                        .withOpacity(0.06),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                decoration: BoxDecoration(
                                  color: isExpiring
                                      ? const Color(0xFFE53935)
                                      : (isUsed
                                          ? Colors.grey.shade300
                                          : AppTheme.primary),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(18),
                                    bottomLeft: Radius.circular(18),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              card.brand,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: isUsed
                                                    ? Colors.grey
                                                    : AppTheme.textSecondary,
                                              ),
                                            ),
                                          ),
                                          if (isExpiring)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE53935)
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(99),
                                              ),
                                              child: Text(
                                                'EXPIRING SOON',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                  color:
                                                      const Color(0xFFE53935),
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          if (isUsed)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.grey
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(99),
                                              ),
                                              child: const Text(
                                                'USED',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.grey,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        card.title,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: isUsed
                                              ? Colors.grey
                                              : AppTheme.textPrimary,
                                          decoration: isUsed
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text(
                                            'Code: ${card.code}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: isUsed
                                                  ? Colors.grey
                                                  : AppTheme.textSecondary,
                                            ),
                                          ),
                                          if (card.expiresIn != null) ...[
                                            const SizedBox(width: 12),
                                            Icon(
                                              Icons.access_time,
                                              size: 12,
                                              color: isExpiring
                                                  ? const Color(0xFFE53935)
                                                  : AppTheme.textSecondary,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              card.expiresIn!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: isExpiring
                                                    ? const Color(0xFFE53935)
                                                    : AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (!isUsed)
                                Container(
                                  width: 1,
                                  color: const Color(0xFFE1BEC0)
                                      .withOpacity(0.4),
                                ),
                              if (!isUsed)
                                SizedBox(
                                  width: 80,
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: const Text(
                                          'USE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

enum _LootStatus { active, used, expiringSoon }

class _LootCard {
  final String title;
  final String brand;
  final String code;
  final _LootStatus status;
  final String? expiresIn;

  const _LootCard({
    required this.title,
    required this.brand,
    required this.code,
    required this.status,
    this.expiresIn,
  });
}
