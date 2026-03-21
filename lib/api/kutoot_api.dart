import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/env.dart';

/// Kutoot API client - mirrors kutootApi.js
class KutootApi {
  static final KutootApi _instance = KutootApi._();
  factory KutootApi() => _instance;

  late final Dio _dio;
  // encryptedSharedPreferences: false avoids release-build crashes on some Android devices
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: false),
  );

  KutootApi._() {
    _dio = Dio(BaseOptions(
      baseUrl: Env.apiBaseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (_) {
          // Storage may fail on some devices; proceed without token
        }
        return handler.next(options);
      },
      onError: (err, handler) async {
        if (err.response?.statusCode == 401) {
          try {
            await _storage.delete(key: 'auth_token');
            await _storage.delete(key: 'user_data');
          } catch (_) {}
        }
        return handler.next(err);
      },
    ));
  }

  Future<void> setToken(String token) async {
    try {
      await _storage.write(key: 'auth_token', value: token);
    } catch (_) {}
  }

  Future<void> clearAuth() async {
    try {
      await _storage.delete(key: 'auth_token');
      await _storage.delete(key: 'user_data');
    } catch (_) {}
  }

  // ─── Auth ─────────────────────────────────────────────────────────
  Future<Response> authConfig() => _dio.get('/auth/config');

  Future<Response> sendOtp(String identifier) =>
      _dio.post('/auth/otp/send', data: {'identifier': identifier});

  /// Dev-only: fetch last OTP for identifier (when backend doesn't return debug_otp in send response)
  Future<Response> getDevOtp(String identifier) =>
      _dio.get('/auth/dev/otp', queryParameters: {'identifier': identifier});

  Future<Response> verifyOtp(String identifier, String otp, {String deviceName = 'flutter-app'}) =>
      _dio.post('/auth/otp/verify', data: {
        'identifier': identifier,
        'otp': otp,
        'device_name': deviceName,
      });

  Future<Response> getUser() => _dio.get('/auth/user');

  Future<Response> logout() => _dio.post('/auth/logout');

  // ─── Dashboard ────────────────────────────────────────────────────
  Future<Response> getDashboard() => _dio.get('/dashboard');

  // ─── Campaigns ────────────────────────────────────────────────────
  Future<Response> getCampaigns({Map<String, dynamic>? params}) =>
      _dio.get('/campaigns', queryParameters: params);

  Future<Response> getCampaign(int id) => _dio.get('/campaigns/$id');

  Future<Response> getCampaignBounty(int id) => _dio.get('/campaigns/$id/bounty');

  // ─── Coupons ──────────────────────────────────────────────────────
  Future<Response> getCoupons({Map<String, dynamic>? params}) =>
      _dio.get('/coupons', queryParameters: params);

  Future<Response> getCoupon(int id) => _dio.get('/coupons/$id');

  Future<Response> redeemCoupon(int couponId, Map<String, dynamic> data) =>
      _dio.post('/coupons/$couponId/redeem', data: data);

  Future<Response> calculateRedemption(Map<String, dynamic> data) =>
      _dio.post('/coupons/calculate', data: data);

  Future<Response> verifyPayment(Map<String, dynamic> data) =>
      _dio.post('/coupons/verify-payment', data: data);

  // ─── Stamps ───────────────────────────────────────────────────────
  Future<Response> getStamps({Map<String, dynamic>? params}) =>
      _dio.get('/stamps', queryParameters: params);

  Future<Response> reserveStamp(int campaignId) =>
      _dio.post('/stamps/reserve', data: {'campaign_id': campaignId});

  // ─── Subscriptions ────────────────────────────────────────────────
  Future<Response> getSubscriptionPlans() => _dio.get('/subscriptions/plans');

  Future<Response> getCurrentSubscription() => _dio.get('/subscriptions/current');

  Future<Response> upgradeSubscription(int planId, {List<int>? campaignSelections}) =>
      _dio.post('/subscriptions/upgrade', data: {
        'plan_id': planId,
        'campaign_selections': campaignSelections ?? [],
        'accepted_terms': true,
      });

  Future<Response> verifySubscriptionPayment(Map<String, dynamic> data) =>
      _dio.post('/subscriptions/verify-payment', data: data);

  // ─── Transactions ───────────────────────────────────────────────
  Future<Response> getTransactions({Map<String, dynamic>? params}) =>
      _dio.get('/transactions', queryParameters: params);

  Future<Response> getTransaction(int id) => _dio.get('/transactions/$id');

  // ─── Profile ──────────────────────────────────────────────────────
  Future<Response> getProfile() => _dio.get('/profile');

  Future<Response> updateProfile(Map<String, dynamic> data) =>
      _dio.patch('/profile', data: data);

  // ─── Merchant Locations (Stores) ──────────────────────────────────
  Future<Response> getMerchantLocations({Map<String, dynamic>? params}) =>
      _dio.get('/merchant-locations', queryParameters: params);

  Future<Response> getStoreCategories({Map<String, dynamic>? params}) =>
      _dio.get('/merchant-locations/store-categories', queryParameters: params);

  Future<Response> getStoresByCategory(int categoryId, {Map<String, dynamic>? params}) =>
      _dio.get('/store-categories/$categoryId/stores', queryParameters: params);

  // ─── Marketing (public) ───────────────────────────────────────────
  Future<Response> getMarketingBanners({Map<String, dynamic>? params}) =>
      _dio.get('/marketing-banners', queryParameters: params);

  Future<Response> getStoreBanners({Map<String, dynamic>? params}) =>
      _dio.get('/store-banners', queryParameters: params);

  Future<Response> getFeaturedBanners({Map<String, dynamic>? params}) =>
      _dio.get('/featured-banners', queryParameters: params);

  Future<Response> getHeroSettings({String? locale}) =>
      _dio.get('/hero-settings', queryParameters: locale != null ? {'locale': locale} : null);

  // ─── QR Scan ──────────────────────────────────────────────────────
  Future<Response> scanQr(String token) => _dio.get('/qr/$token/scan');

  // ─── Terms ────────────────────────────────────────────────────────
  Future<Response> getCurrentTerms() => _dio.get('/terms/current');

  Future<Response> acceptTerms(int version) =>
      _dio.post('/terms/accept', data: {'version': version});
}
