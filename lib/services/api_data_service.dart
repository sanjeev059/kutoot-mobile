import '../api/kutoot_api.dart';

/// Centralized data service — fetches from API, falls back to static data.
class ApiDataService {
  static final _api = KutootApi();

  // ─── Stores ────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchStores({
    String? search,
    int? categoryId,
  }) async {
    try {
      List items = [];

      if (categoryId != null && categoryId > 0) {
        final res = await _api.getStoresByCategory(categoryId,
            params: search != null && search.isNotEmpty
                ? {'search': search}
                : null);
        final raw = res.data;
        if (raw is Map && raw['data'] is List) {
          items = raw['data'] as List;
        } else if (raw is List) {
          items = raw;
        }
      } else {
        final params = <String, dynamic>{'per_page': 50};
        if (search != null && search.isNotEmpty) params['search'] = search;
        final res = await _api.getMerchantLocations(params: params);
        final raw = res.data;
        if (raw is Map && raw['data'] is List) {
          items = raw['data'] as List;
        } else if (raw is List) {
          items = raw;
        }
      }

      if (items.isEmpty) return _fallbackStores;

      return items.map<Map<String, dynamic>>((item) {
        final m =
            item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
        final merchant = m['merchant'] is Map
            ? Map<String, dynamic>.from(m['merchant'] as Map)
            : <String, dynamic>{};
        final name = merchant['name']?.toString() ??
            m['branch_name']?.toString() ??
            'Store';
        final img = _resolveImage(m, merchant);

        return {
          'id': m['id'] ?? 0,
          'name': name,
          'branch_name': m['branch_name']?.toString() ?? name,
          'image': img,
          'badge': '',
          'rating': (m['star_rating'] ?? '4.5').toString(),
          'distance': m['distance']?.toString() ?? '',
          'address': m['address']?.toString() ?? '',
          'city': m['city'] is Map ? m['city']['name']?.toString() ?? '' : '',
          'opening_hours':
              m['opening_hours']?.toString() ?? '11:00 AM - 10:00 PM',
          'commission_percentage': m['commission_percentage'] ?? 0,
          'is_demo_store': false,
          'source': 'api',
        };
      }).toList();
    } catch (_) {
      return _fallbackStores;
    }
  }

  static String _resolveImage(
      Map<String, dynamic> m, Map<String, dynamic> merchant) {
    if (m['media'] is List && (m['media'] as List).isNotEmpty) {
      final first = (m['media'] as List).first;
      if (first is Map && first['url'] != null) {
        return first['url'].toString();
      }
    }
    if (merchant['media'] is List && (merchant['media'] as List).isNotEmpty) {
      final first = (merchant['media'] as List).first;
      if (first is Map) {
        return first['preview']?.toString() ?? first['url']?.toString() ?? '';
      }
    }
    final logo = merchant['logo_url']?.toString() ?? '';
    if (logo.isNotEmpty) return logo;
    return 'https://via.placeholder.com/400x300?text=Store';
  }

  // ─── Store Categories ──────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchCategories() async {
    try {
      final res = await _api.getStoreCategories();
      final raw = res.data;
      List items = [];
      if (raw is Map && raw['data'] is List) {
        items = raw['data'] as List;
      } else if (raw is List) {
        items = raw;
      }

      if (items.isEmpty) return _fallbackCategories;

      final cats = <Map<String, dynamic>>[
        {'id': 0, 'name': 'ALL', 'icon': 'grid_view'},
      ];

      for (final item in items) {
        final m =
            item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
        cats.add({
          'id': m['id'] ?? 0,
          'name': (m['name'] ?? '').toString().toUpperCase(),
          'icon': m['icon']?.toString() ?? 'category',
        });
      }
      return cats;
    } catch (_) {
      return _fallbackCategories;
    }
  }

  // ─── Marketing Banners ──────────────────────────────────────────────
  static Future<List<String>> fetchBannerUrls() async {
    try {
      final res = await _api.getMarketingBanners();
      final raw = res.data;
      List items = [];
      if (raw is Map && raw['data'] is List) {
        items = raw['data'] as List;
      } else if (raw is List) {
        items = raw;
      }

      final urls = <String>[];
      for (final item in items) {
        final m =
            item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
        final url = m['image_url']?.toString() ?? m['url']?.toString() ?? '';
        if (url.isNotEmpty) urls.add(url);
        if (m['media'] is List) {
          for (final media in (m['media'] as List)) {
            if (media is Map && media['url'] != null) {
              urls.add(media['url'].toString());
            }
          }
        }
      }
      return urls.isEmpty ? _fallbackBannerUrls : urls;
    } catch (_) {
      return _fallbackBannerUrls;
    }
  }

  // ─── Subscription Plans ─────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchPlans() async {
    try {
      final res = await _api.getSubscriptionPlans();
      final raw = res.data;
      List items = [];
      if (raw is Map && raw['data'] is List) {
        items = raw['data'] as List;
      } else if (raw is List) {
        items = raw;
      }

      if (items.isEmpty) return _fallbackPlans;

      return items.map<Map<String, dynamic>>((item) {
        final m =
            item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
        final durationDays = m['duration_days'] ?? m['validity_days'] ?? 0;
        return {
          'id': m['id'] ?? 0,
          'name': m['name']?.toString() ?? 'Plan',
          'slug': m['slug']?.toString() ??
              (m['name']?.toString() ?? '').toLowerCase(),
          'price': (m['price'] ?? 0).toString(),
          'original_price': m['original_price']?.toString(),
          'best_value': m['best_value'] == true,
          'validity_days': durationDays,
          'validity': _formatValidity(durationDays),
          'max_discounted_bills': m['max_discounted_bills'] ?? 0,
          'max_redeemable_amount': m['max_redeemable_amount'] ?? 0,
          'stamps_per_transaction':
              m['stamps_per_denomination'] ?? m['stamp_denomination'] ?? 0,
          'stamps_on_purchase': m['stamps_on_purchase'] ?? 0,
          'stamp_denomination': m['stamp_denomination'] ?? 1,
          'stamps_per_denomination': m['stamps_per_denomination'] ?? 1,
          'is_default': m['is_default'] == true,
          'sort_order': m['sort_order'] ?? 0,
          'terms_and_conditions': m['terms_and_conditions']?.toString() ?? '',
          'coupon_categories': m['coupon_categories'] ?? [],
          'campaigns': m['campaigns'] ?? [],
        };
      }).toList();
    } catch (_) {
      return _fallbackPlans;
    }
  }

  static String _formatValidity(dynamic days) {
    if (days == null || days == 0) return 'Forever';
    final d = int.tryParse(days.toString()) ?? 0;
    if (d <= 1) return '/ 1 day';
    if (d <= 7) return '/ $d days';
    if (d <= 30) return '/ $d days';
    return '/ $d days';
  }

  // ─── Campaigns ──────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchCampaigns(
      {String? status}) async {
    try {
      final params = <String, dynamic>{'per_page': 50};
      if (status != null) params['status'] = status;

      final res = await _api.getCampaigns(params: params);
      final raw = res.data;
      List items = [];
      if (raw is Map && raw['data'] is List) {
        items = raw['data'] as List;
      } else if (raw is List) {
        items = raw;
      }

      if (items.isEmpty) return [];

      return items.map<Map<String, dynamic>>((item) {
        final m =
            item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
        return {
          'id': m['id'] ?? 0,
          'title': m['reward_name']?.toString() ??
              m['code']?.toString() ??
              'Campaign',
          'code': m['code']?.toString() ?? '',
          'description': m['description']?.toString() ?? '',
          'stamp_target': m['stamp_target'] ?? 0,
          'issued_stamps': m['issued_stamps_cache'] ?? 0,
          'status': m['status']?.toString() ?? 'active',
          'is_active': m['is_active'] == true,
          'bounty_percentage': m['bounty_percentage'] ?? 0,
          'image': _resolveCampaignImage(m),
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static String _resolveCampaignImage(Map<String, dynamic> m) {
    if (m['banner_url'] != null && m['banner_url'].toString().isNotEmpty) {
      return m['banner_url'].toString();
    }
    if (m['media'] is List && (m['media'] as List).isNotEmpty) {
      final first = (m['media'] as List).first;
      if (first is Map) {
        return first['original_url']?.toString() ??
            first['url']?.toString() ??
            '';
      }
    }
    return '';
  }

  // ─── Coupons / Deals ────────────────────────────────────────────────
  static Future<Map<String, dynamic>> fetchCoupons(
      {int? merchantLocationId}) async {
    try {
      final params = <String, dynamic>{'per_page': 50};
      if (merchantLocationId != null) {
        params['merchant_location_id'] = merchantLocationId;
      }

      final res = await _api.getCoupons(params: params);
      final raw = res.data;

      if (raw is Map && raw['data'] is Map) {
        final data = Map<String, dynamic>.from(raw['data'] as Map);
        final meta = raw['meta'] is Map
            ? Map<String, dynamic>.from(raw['meta'] as Map)
            : <String, dynamic>{};

        return {
          'plan_coupons': _parseCouponList(data['plan_coupons']),
          'store_coupons': _parseCouponList(data['store_coupons']),
          'other_coupons': _parseCouponList(data['other_coupons']),
          'meta': meta,
        };
      }

      if (raw is Map && raw['data'] is List) {
        return {
          'plan_coupons': _parseCouponList(raw['data']),
          'store_coupons': <Map<String, dynamic>>[],
          'other_coupons': <Map<String, dynamic>>[],
          'meta': <String, dynamic>{},
        };
      }

      return _emptyCouponsResult;
    } catch (_) {
      return _emptyCouponsResult;
    }
  }

  static List<Map<String, dynamic>> _parseCouponList(dynamic list) {
    if (list is! List) return [];
    return list.map<Map<String, dynamic>>((item) {
      final m =
          item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
      return {
        'id': m['id'] ?? 0,
        'code': m['code']?.toString() ?? '',
        'title': m['title']?.toString() ?? '',
        'description': m['description']?.toString() ?? '',
        'discount_type': m['discount_type']?.toString() ?? 'fixed',
        'discount_value': m['discount_value'] ?? 0,
        'max_discount_amount': m['max_discount_amount'],
        'min_order_value': m['min_order_value'],
        'is_eligible': m['is_eligible'] == true,
        'remaining_usage': m['remaining_usage'] ?? 0,
        'required_plan': m['required_plan'],
        'segment': m['segment']?.toString() ?? 'other',
        'merchant_location': m['merchant_location'],
        'category': m['category'],
      };
    }).toList();
  }

  static final Map<String, dynamic> _emptyCouponsResult = {
    'plan_coupons': <Map<String, dynamic>>[],
    'store_coupons': <Map<String, dynamic>>[],
    'other_coupons': <Map<String, dynamic>>[],
    'meta': <String, dynamic>{},
  };

  // ─── Bill Calculation (preview) ─────────────────────────────────────
  static Future<Map<String, dynamic>?> calculateBill({
    required double billAmount,
    required int merchantLocationId,
    int? couponId,
    String? couponCode,
  }) async {
    try {
      final data = <String, dynamic>{
        'bill_amount': billAmount,
        'merchant_location_id': merchantLocationId,
      };
      if (couponId != null) data['coupon_id'] = couponId;
      if (couponCode != null) data['coupon_code'] = couponCode;

      final res = await _api.calculateRedemption(data);
      if (res.data is Map) {
        return Map<String, dynamic>.from(res.data as Map);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─── Transactions ───────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchTransactions() async {
    try {
      final res = await _api.getTransactions();
      final raw = res.data;
      List items = [];
      if (raw is Map && raw['data'] is List) {
        items = raw['data'] as List;
      } else if (raw is List) {
        items = raw;
      }

      return items.map<Map<String, dynamic>>((item) {
        return item is Map
            ? Map<String, dynamic>.from(item)
            : <String, dynamic>{};
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Support Tickets ────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchSupportTickets() async {
    try {
      final res =
          await _api.getTransactions(); // Using transactions endpoint as proxy
      // The real endpoint would be support tickets
      final raw = res.data;
      List items = [];
      if (raw is Map && raw['data'] is List) {
        items = raw['data'] as List;
      } else if (raw is List) {
        items = raw;
      }

      return items.map<Map<String, dynamic>>((item) {
        return item is Map
            ? Map<String, dynamic>.from(item)
            : <String, dynamic>{};
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  FALLBACK STATIC DATA (used when API is unavailable)
  // ═══════════════════════════════════════════════════════════════════

  static final List<String> _fallbackBannerUrls = [
    'https://lh3.googleusercontent.com/aida-public/AB6AXuCPH9hMRCozh3NfthtmLUKM6o287QOpScFM7sZ1vv6CrYy63ww2DV_t4JFmMZL3kEB_Dr7EAmhF8l0bHvPpTNRConFTaAFvxbewYzw8DrCf9ffWdOoulpmTlPy8WaqZeujPiC199Y0uhnmERB14HOa29AbH4dc10mOmo9hZb1O3x0D15yazXmi2SqdtwfyAOFLbo1qKrDIlvtAUu1Ja6CBiCA4cOUDl8Z8bmpehyRtcECfYmHsUzADG8PeATdI0NO9eW2tJ3iFPaVDp',
  ];

  static final List<Map<String, dynamic>> _fallbackCategories = [
    {'id': 0, 'name': 'ALL', 'icon': 'grid_view'},
    {'id': 1, 'name': 'FASHION', 'icon': 'checkroom'},
    {'id': 2, 'name': 'ELECTRONICS', 'icon': 'devices_other'},
    {'id': 3, 'name': 'HOME', 'icon': 'chair'},
    {'id': 4, 'name': 'BEAUTY', 'icon': 'spa'},
  ];

  static final List<Map<String, dynamic>> _fallbackStores = [
    {
      'id': 101,
      'name': 'Westside',
      'category': 'FASHION',
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuC-G-9JECKc4p-QWP2LcUZycO_1MrQk6lY9_tzqV_OEFbUimLGUT63ICHGRgaMnVslwyryofi3hAO-R_PRGPWK4Q_GiiQCbDdur4do_MaV-ddX7NbEBhi6FJsAlUBODWGe4sqAqfHqEfxPmRJ5EAJm3O8ZP_HdxZLrI0Pn5ZEQ--6yY-x24M9W9i6JHXwsM6vRmAvBsQx16-l50FCqp6twRNIWJUXcouZMYdxmFGrzM8RyNwWskC48v32ktcLOfzQGVNEbrRJosrZhm',
      'badge': '15% OFF',
      'rating': '4.5',
      'distance': '1.2 km',
      'is_demo_store': true,
      'source': 'home_static',
    },
    {
      'id': 102,
      'name': 'Croma',
      'category': 'ELECTRONICS',
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAUDHP3i51_AfeqtPe-dzEkR4HWCjgcnjEwU44IG3_sD8Ui2-XaLe-rPaAH9ILxU3uZAT1xMGXorP6yVustg6lFMyagLgupRbO37jsYuXgQL6h3efR8uk-JbZV4g02Wo3iHRmVt3CpCT6cw3Bqvz96k_r1QwOx56g2PHd9-QWwGYaT5Is4k-FXLC-MPnm_oDzcxkziZGl-mpJMjScJnoCOojnbN6ttS2Dr2dShDSEkn5-M83mBwDvg62ZKioLvJlGMBXpXN5HgzwQu1',
      'badge': 'EXCLUSIVE',
      'rating': '4.7',
      'distance': '2.1 km',
      'is_demo_store': true,
      'source': 'home_static',
    },
    {
      'id': 103,
      'name': 'Reliance Digital',
      'category': 'ELECTRONICS',
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAfYcqf6LF2jIg9uNMLSLCNPhurMGTqyKtihB8_sjbCaSIPNyvr9WWofdp35dY5nOb3MiQVQlHnZs6Ik7D9Q9jNQ5hBqV1_FOn72NufxfV59Hbz-mhRUAXoXzWA9h9_S10q3Dww2zro_DdIwC06-kSHQ1iaj0XFB5MTMWsSR7v_C4Jhkq0LR_jvEveNv7fOtvC6UR-aydqop_SqGEgUWCeGd5VAYOCoQ3dJdVf3Z3CsDI1xslffQtOfzBeXTgUJH1escO6PWZR8esI',
      'badge': '10% OFF',
      'rating': '4.4',
      'distance': '1.9 km',
      'is_demo_store': true,
      'source': 'home_static',
    },
    {
      'id': 104,
      'name': 'Nykaa Luxe',
      'category': 'BEAUTY',
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDMQ8epcMm-c6LllV8dXvZFaapPJd5hz-EmlGWv8ItN6OLpKPTc-reumCV6Pm3193580lp1cLKh5sGupU470ffI-laRJNFFKmlwvHPjYHUKoczHmhzeoN-aSM3D9MdEEsiYXOuyWwp6nGh724UIg2WzY7s57L1oE2mNwphs-OUJtUHSJiiVCVmS4dSrAPmmYgUe4_I-J8qPMuzg3ABGlTcVf5-5qoKv3wGHxqIl6v5qtU3kZJwJ6dazxfg0Min-Y7DqBfjznNvls_g',
      'badge': 'FLAT ₹500',
      'rating': '4.9',
      'distance': '1.5 km',
      'is_demo_store': true,
      'source': 'home_static',
    },
    {
      'id': 105,
      'name': 'Home Centre',
      'category': 'HOME',
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuC8S9lnC0l-6bxkdx4sx7b96JcGcAH0AEdqPCvAhm8wVZnTywYsMWEDbxn1oTDV61KZbQET06wsKc4_vIXehaIl25sMPEomuuorwsK-Y54fOrueEeCW9OSlY6HlksO416zUNzgU-26CgQU_vs6GNPDOH9HhZDcPQv9jy2JQ_5Z3LyNFdsfRTcTeFJ_hC1YwQhXSEIV0XswHW7aK2jtT6uthtP4LBn4ftAj84mvpswr8IsVka1BztAdvMcXfuHYQQEzL7ouq1ron7sw',
      'badge': '10% OFFER',
      'rating': '4.2',
      'distance': '2.4 km',
      'is_demo_store': true,
      'source': 'home_static',
    },
  ];

  static final List<Map<String, dynamic>> _fallbackPlans = [
    {
      'id': 0,
      'name': 'Free',
      'slug': 'free',
      'price': '0',
      'validity': 'Forever',
      'validity_days': 0,
      'max_discounted_bills': 5,
      'max_redeemable_amount': 500,
      'stamps_per_transaction': 1,
      'stamps_on_purchase': 0,
      'is_default': true
    },
    {
      'id': 1,
      'name': 'Basic',
      'slug': 'basic',
      'price': '149',
      'validity': '/ 1 day',
      'validity_days': 1,
      'max_discounted_bills': 20,
      'max_redeemable_amount': 2200,
      'stamps_per_transaction': 1,
      'stamps_on_purchase': 5,
      'is_default': false
    },
    {
      'id': 2,
      'name': 'Pro',
      'slug': 'pro',
      'price': '399',
      'validity': '/ 7 days',
      'validity_days': 7,
      'max_discounted_bills': 60,
      'max_redeemable_amount': 7000,
      'stamps_per_transaction': 1,
      'stamps_on_purchase': 12,
      'is_default': false
    },
    {
      'id': 3,
      'name': 'VIP',
      'slug': 'vip',
      'price': '799',
      'validity': '/ 15 days',
      'validity_days': 15,
      'max_discounted_bills': 120,
      'max_redeemable_amount': 15000,
      'stamps_per_transaction': 1,
      'stamps_on_purchase': 25,
      'is_default': false
    },
    {
      'id': 4,
      'name': 'Elite',
      'slug': 'elite',
      'price': '1499',
      'validity': '/ 30 days',
      'validity_days': 30,
      'max_discounted_bills': 999,
      'max_redeemable_amount': 50000,
      'stamps_per_transaction': 1,
      'stamps_on_purchase': 50,
      'is_default': false
    },
  ];

  static const List<Map<String, dynamic>> fallbackLiveCampaigns = [
    {
      'id': 1,
      'title': 'LUXURY VILLA',
      'stamps': 12,
      'progress': 82,
      'live': true
    },
    {
      'id': 2,
      'title': 'BMW M4 COMPETITION',
      'stamps': 5,
      'progress': 45,
      'live': true
    },
    {
      'id': 3,
      'title': '1KG GOLD BAR',
      'stamps': 1,
      'progress': 94,
      'live': true
    },
  ];

  static const List<Map<String, dynamic>> fallbackAnnouncedCampaigns = [
    {
      'id': 4,
      'title': 'MALDIVES TRIP',
      'stamps': 0,
      'progress': 0,
      'live': false
    },
    {
      'id': 5,
      'title': 'IPHONE PRO MAX',
      'stamps': 0,
      'progress': 0,
      'live': false
    },
    {
      'id': 6,
      'title': 'PREMIUM HOME MAKEOVER',
      'stamps': 0,
      'progress': 0,
      'live': false
    },
  ];
}
