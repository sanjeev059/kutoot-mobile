import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../screens/stores/store_profile_screen.dart';
import '../theme/app_theme.dart';

/// Zomato-style filter chips + horizontal platform coupon cards.
class ExploreModeCouponsStrip extends StatefulWidget {
  final VoidCallback onViewCampaigns;

  const ExploreModeCouponsStrip({
    super.key,
    required this.onViewCampaigns,
  });

  @override
  State<ExploreModeCouponsStrip> createState() =>
      _ExploreModeCouponsStripState();
}

class _CouponDef {
  final String title;
  final String subtitle;
  final String tag;
  final Color tagColor;
  final Color g1;
  final Color g2;
  final Set<String> modes;

  const _CouponDef({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.tagColor,
    required this.g1,
    required this.g2,
    required this.modes,
  });
}

class _ExploreModeCouponsStripState extends State<ExploreModeCouponsStrip> {
  static const _filters = <(String id, String label)>[
    ('all', 'All'),
    ('stamps', 'Stamp rewards'),
    ('fresh', 'New on Kutoot'),
    ('partners', 'Partner picks'),
  ];

  static const _coupons = <_CouponDef>[
    _CouponDef(
      title: '2× stamps on UPI pay',
      subtitle: 'Pay with Kutoot at partner stores',
      tag: 'STAMPS',
      tagColor: Color(0xFFE53935),
      g1: Color(0xFFC62828),
      g2: Color(0xFF8E0000),
      modes: {'all', 'stamps', 'partners'},
    ),
    _CouponDef(
      title: 'Weekend reward boost',
      subtitle: 'Sat–Sun extra stamps on bills',
      tag: 'WEEKEND',
      tagColor: Color(0xFFFFA000),
      g1: Color(0xFFE65100),
      g2: Color(0xFFFF7A2E),
      modes: {'all', 'stamps', 'fresh'},
    ),
    _CouponDef(
      title: 'New stores welcome pack',
      subtitle: 'Bonus stamps on first visit',
      tag: 'NEW',
      tagColor: Color(0xFF43A047),
      g1: Color(0xFF2E7D32),
      g2: Color(0xFF1B5E20),
      modes: {'all', 'fresh', 'partners'},
    ),
    _CouponDef(
      title: 'Platform fee savings',
      subtitle: 'Fair checkout on every order',
      tag: 'SAVE',
      tagColor: Color(0xFF1565C0),
      g1: Color(0xFF1565C0),
      g2: Color(0xFF0D47A1),
      modes: {'all', 'partners'},
    ),
    _CouponDef(
      title: 'Scan QR · earn stamps',
      subtitle: 'Show your code when you pay',
      tag: 'QR PAY',
      tagColor: Color(0xFF7B1FA2),
      g1: Color(0xFF6A1B9A),
      g2: Color(0xFF4A148C),
      modes: {'all', 'stamps'},
    ),
  ];

  String _filterId = 'all';

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _coupons
        .where((c) => _filterId == 'all' || c.modes.contains(_filterId))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'EXPLORE',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.5,
                  color: context.kutootMutedText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: widget.onViewCampaigns,
              child: const Text(
                'VIEW ALL  ▶',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final f = _filters[i];
              final on = f.$1 == _filterId;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _filterId = f.$1),
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: on
                          ? AppTheme.primary
                          : (dark
                              ? const Color(0xFF2C2C2E)
                              : const Color(0xFFF0F0F2)),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: on
                            ? AppTheme.primary
                            : (dark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06)),
                      ),
                    ),
                    child: Text(
                      f.$2,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: on
                            ? Colors.white
                            : (dark
                                ? Colors.white.withValues(alpha: 0.85)
                                : const Color(0xFF1C1C1E)),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Text(
            'Nothing in this tab yet — try another.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.kutootMutedText,
            ),
          )
        else
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final c = filtered[i];
                return _ExploreCouponCard(
                  title: c.title,
                  subtitle: c.subtitle,
                  tag: c.tag,
                  tagColor: c.tagColor,
                  g1: c.g1,
                  g2: c.g2,
                  onTap: widget.onViewCampaigns,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ExploreCouponCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String tag;
  final Color tagColor;
  final Color g1;
  final Color g2;
  final VoidCallback onTap;

  const _ExploreCouponCard({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.tagColor,
    required this.g1,
    required this.g2,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 200,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [g1, g2],
            ),
            boxShadow: [
              BoxShadow(
                color: g1.withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: tagColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 8,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  height: 1.2,
                ),
              ),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _offerLineForStore(Map<String, dynamic> store) {
  if (store['is_new'] == true) return 'NEW · Member rewards';
  if (store['is_trending'] == true) return 'TRENDING · Kutoot picks';
  if (store['is_hot_deal'] == true) return 'HOT DEAL · Pay & earn stamps';
  final d = store['discount'];
  if (d != null) {
    final n = d is num ? d : num.tryParse(d.toString());
    if (n != null && n > 0) return '${n.toStringAsFixed(0)}% off · Rewards';
  }
  return 'Rewards on every visit';
}

String _etaLineForStore(Map<String, dynamic> store) {
  final pm = store['proximity_meters'];
  if (pm is num && pm < 5000) {
    final meters = pm.round();
    if (meters < 1000) {
      return '$meters m away · walk in & pay with Kutoot';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
  final dist = store['distance']?.toString().trim() ?? '';
  if (dist.isNotEmpty) {
    return dist.toLowerCase().contains('km') || dist.toLowerCase().contains('m')
        ? dist
        : '$dist away';
  }
  final id = store['id'] ?? 0;
  final h = id.hashCode.abs();
  final lo = 22 + (h % 18);
  final hi = lo + 8;
  return '$lo–$hi min';
}

/// Horizontal “Recommended for you” row (Zomato-style wide cards).
class RecommendedForYouRow extends StatelessWidget {
  final List<Map<String, dynamic>> stores;
  /// When true, list is ordered by live proximity (GPS + store coordinates).
  final bool sortedByProximity;

  const RecommendedForYouRow({
    super.key,
    required this.stores,
    this.sortedByProximity = false,
  });

  @override
  Widget build(BuildContext context) {
    if (stores.isEmpty) return const SizedBox.shrink();
    final slice = stores.length > 8 ? stores.sublist(0, 8) : stores;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECOMMENDED FOR YOU',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.5,
            color: context.kutootMutedText,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (sortedByProximity) ...[
          const SizedBox(height: 4),
          Text(
            'Places near you right now appear first',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.kutootMutedText.withValues(alpha: 0.9),
            ),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          height: 232,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: slice.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _RecommendedZomatoCard(
              store: slice[i],
              cardWidth: 272,
            ),
          ),
        ),
      ],
    );
  }
}

/// Full vertical list of stores (Zomato-style cards) after savings / promos.
class ZomatoStyleAllStoresSection extends StatelessWidget {
  final List<Map<String, dynamic>> stores;
  final VoidCallback? onSeeAll;
  final int maxVisible;

  const ZomatoStyleAllStoresSection({
    super.key,
    required this.stores,
    this.onSeeAll,
    this.maxVisible = 30,
  });

  @override
  Widget build(BuildContext context) {
    if (stores.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No stores in this area yet. Try another category or city.',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.kutootMutedText,
          ),
        ),
      );
    }
    final w = MediaQuery.sizeOf(context).width - 32;
    final n = stores.length;
    final show = n > maxVisible ? maxVisible : n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'ALL STORES',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.5,
                  color: context.kutootMutedText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (onSeeAll != null)
              TextButton(
                onPressed: onSeeAll,
                child: const Text(
                  'SEE ALL  ▶',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Pay with Kutoot · earn stamps at every partner',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: context.kutootMutedText.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          show,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: i == show - 1 ? 0 : 12),
            child: _RecommendedZomatoCard(
              store: stores[i],
              cardWidth: w,
              imageHeight: 128,
            ),
          ),
        ),
        if (n > maxVisible && onSeeAll != null) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: onSeeAll,
              child: Text(
                'See all $n stores',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RecommendedZomatoCard extends StatelessWidget {
  final Map<String, dynamic> store;
  final double cardWidth;
  final double imageHeight;

  const _RecommendedZomatoCard({
    required this.store,
    required this.cardWidth,
    this.imageHeight = 132,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final name = store['name']?.toString() ?? 'Store';
    final image = store['image']?.toString().trim() ?? '';
    final rating = store['star_rating']?.toString() ??
        store['rating']?.toString() ??
        '4.2';
    final offer = _offerLineForStore(store);
    final eta = _etaLineForStore(store);

    return SizedBox(
      width: cardWidth,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => StoreProfileScreen(store: store),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1C1C1E)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: dark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.35 : 0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: imageHeight,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (image.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: image,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            child: const Icon(Icons.store_rounded,
                                size: 40, color: AppTheme.primary),
                          ),
                        )
                      else
                        Container(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          child: const Icon(Icons.store_rounded,
                              size: 40, color: AppTheme.primary),
                        ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.05),
                                Colors.black.withValues(alpha: 0.45),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        right: store['proximity_here_now'] == true ? 8 : 48,
                        child: Row(
                          children: [
                            if (store['proximity_here_now'] == true) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF43A047),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'NEAR YOU',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  offer,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1BA162),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 12, color: Colors.white),
                              const SizedBox(width: 3),
                              Text(
                                rating,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                      color: context.kutootOnSurface,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 15,
                        color: AppTheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          eta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.kutootMutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
