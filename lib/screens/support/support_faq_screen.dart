import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SupportFaqScreen extends StatefulWidget {
  const SupportFaqScreen({super.key});

  @override
  State<SupportFaqScreen> createState() => _SupportFaqScreenState();
}

class _SupportFaqScreenState extends State<SupportFaqScreen> {
  int? _activeCategoryIndex = 1;

  static const _categories = [
    _Category(icon: Icons.payments, label: 'Payments'),
    _Category(icon: Icons.workspace_premium, label: 'Rewards'),
    _Category(icon: Icons.approval, label: 'Stamps'),
    _Category(icon: Icons.card_membership, label: 'Plans'),
    _Category(icon: Icons.account_circle, label: 'Account'),
  ];

  static const Map<int, List<_FaqItem>> _categoryFaqs = {
    0: [
      _FaqItem(
        q: 'How do I make a payment?',
        a: 'You can pay at any participating store by scanning your Kutoot QR code. Enter the bill amount and choose your preferred payment method to complete the transaction.',
      ),
      _FaqItem(
        q: 'What payment methods are supported?',
        a: 'We support UPI (Google Pay, PhonePe), credit/debit cards, and net banking through our secure payment gateway powered by Razorpay.',
      ),
      _FaqItem(
        q: 'My payment failed. What should I do?',
        a: 'If your payment failed, the amount will be refunded within 3-5 business days. You can retry the payment or contact support for assistance.',
      ),
    ],
    1: [
      _FaqItem(
        q: 'How do I earn stamps?',
        a: 'Earning stamps is easy! Simply scan your unique Kutoot QR code at any '
            'participating merchant whenever you make a purchase. Each qualified '
            'purchase adds one stamp to your digital card. Once you collect 10 '
            'stamps, your reward is automatically unlocked.',
      ),
      _FaqItem(
        q: 'When is the next lucky draw?',
        a: 'Our Grand Kinetic Lucky Draw happens every last Friday of the month! '
            'You can enter by redeeming your accumulated rewards points for draw '
            "tickets in the 'Rewards' tab. Make sure your profile is fully verified "
            'to participate.',
      ),
      _FaqItem(
        q: 'How to upgrade my plan?',
        a: "To upgrade your membership plan, navigate to the Profile section and "
            "select 'Member Status'. There you can compare our Premium and Elite "
            'tiers and choose the one that fits your lifestyle. Payments are '
            'processed securely via your saved method.',
      ),
      _FaqItem(
        q: "What happens if a merchant doesn't scan?",
        a: "If you encounter a scanning issue, please ask the merchant for a "
            "physical receipt and use the 'Report Missing Stamp' feature in the "
            'Support menu. Upload a photo of your receipt and our team will credit '
            'your account within 24 hours.',
      ),
    ],
    2: [
      _FaqItem(
        q: 'How do I earn stamps?',
        a: 'Earning stamps is easy! Simply scan your Kutoot QR code at any participating merchant. Each qualified purchase adds stamps based on your plan tier.',
      ),
      _FaqItem(
        q: 'How many stamps do I need to enter a campaign?',
        a: 'Each campaign has different stamp requirements. Check the campaign details in the Rewards section to see the required stamps for each prize.',
      ),
      _FaqItem(
        q: 'Do my stamps expire?',
        a: 'Stamps are valid for the duration of your active plan. Once your plan expires, unused stamps will be carried forward for 30 days.',
      ),
    ],
    3: [
      _FaqItem(
        q: 'How to upgrade my plan?',
        a: 'Navigate to the Plans section from the bottom navigation. Browse available plans and tap to select one that suits your needs. Complete payment to activate instantly.',
      ),
      _FaqItem(
        q: 'Can I downgrade my plan?',
        a: 'Plan downgrades are not available during an active subscription period. Once your current plan expires, you can choose any plan including a lower tier.',
      ),
      _FaqItem(
        q: 'What happens when my plan expires?',
        a: 'When your plan expires, you will revert to the Free tier. Your stamps and transaction history are preserved. You can upgrade again at any time.',
      ),
    ],
    4: [
      _FaqItem(
        q: 'How do I edit my profile?',
        a: 'Go to Account section and tap on your profile card. You can update your name, email, and profile picture from the edit screen.',
      ),
      _FaqItem(
        q: 'How to delete my account?',
        a: 'Navigate to Account > Settings > Delete Account. Please note this action is irreversible and all your data, stamps, and rewards will be permanently removed.',
      ),
      _FaqItem(
        q: 'How do I change my phone number?',
        a: 'For security reasons, changing your registered phone number requires verification. Please contact support through the Get Support button.',
      ),
    ],
  };

  List<_FaqItem> get _activeFaqs {
    return _categoryFaqs[_activeCategoryIndex ?? 1] ?? _categoryFaqs[1]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _buildCategories(),
                  const SizedBox(height: 28),
                  _buildFaqList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD5C8BE).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          ),
          const Expanded(
            child: Text(
              'Kutoot Support',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Browse Categories',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(_categories.length, (i) {
            final cat = _categories[i];
            final active = _activeCategoryIndex == i;
            return GestureDetector(
              onTap: () => setState(() => _activeCategoryIndex = i),
              child: Container(
                width: (MediaQuery.of(context).size.width - 40 - 12) / 2,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: active
                      ? AppTheme.secondaryContainer
                      : AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppTheme.secondaryContainer
                                .withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: active
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                ),
                              ],
                      ),
                      child: Icon(
                        cat.icon,
                        color: active ? Colors.white : AppTheme.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: active ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFaqList() {
    final faqs = _activeFaqs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frequently Asked Questions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(
            faqs.length, (i) => _FaqTile(q: faqs[i].q, a: faqs[i].a)),
      ],
    );
  }
}

class _Category {
  final IconData icon;
  final String label;
  const _Category({required this.icon, required this.label});
}

class _FaqItem {
  final String q;
  final String a;
  const _FaqItem({required this.q, required this.a});
}

class _FaqTile extends StatefulWidget {
  final String q;
  final String a;
  const _FaqTile({required this.q, required this.a});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late final AnimationController _iconController;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _iconController.forward();
    } else {
      _iconController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _open
            ? [
                BoxShadow(
                  color: const Color(0xFFD5C8BE).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.q,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 0.5).animate(_iconController),
                    child: const Icon(Icons.expand_more,
                        color: AppTheme.primary, size: 24),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            clipBehavior: Clip.hardEdge,
            child: AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: Text(
                    widget.a,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              crossFadeState:
                  _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ),
        ],
      ),
    );
  }
}
