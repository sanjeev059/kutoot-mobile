import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/env.dart';
import '../services/device_service.dart';

/// Kutoot API client — mostly `/api/mobile`; payments use `/api/v1` (same as web).
class KutootApi {
  static final KutootApi _instance = KutootApi._();
  factory KutootApi() => _instance;

  /// Called after a 401 clears the stored token (e.g. sync [AuthProvider]).
  static void Function()? onSessionExpired;

  late final Dio _dio;
  late final Dio _dioV1;
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: false),
  );

  /// Parses mobile API envelopes: `{ "success": true, "data": { ... } }`.
  static Map<String, dynamic>? unwrapSuccessData(dynamic body) {
    if (body is! Map) return null;
    final m = Map<String, dynamic>.from(body);
    if (m['success'] == true && m['data'] is Map) {
      return Map<String, dynamic>.from(m['data'] as Map);
    }
    return null;
  }

  KutootApi._() {
    _dio = _createDio(Env.apiBaseUrl);
    _dioV1 = _createDio(Env.apiV1BaseUrl);
  }

  Dio _createDio(String baseUrl) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (_) {}

        try {
          final deviceHeaders = await DeviceService().getDeviceHeaders();
          options.headers.addAll(deviceHeaders);
        } catch (_) {}

        return handler.next(options);
      },
      onError: (err, handler) async {
        if (err.response?.statusCode == 401) {
          try {
            await _storage.delete(key: 'auth_token');
            await _storage.delete(key: 'user_data');
          } catch (_) {}
          try {
            onSessionExpired?.call();
          } catch (_) {}
        }
        return handler.next(err);
      },
    ));
    return dio;
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

  /// Non-null when a session token exists (may still be expired).
  Future<String?> readAuthToken() async {
    try {
      return await _storage.read(key: 'auth_token');
    } catch (_) {
      return null;
    }
  }

  // ─── Auth ─────────────────────────────────────────────────────────
  Future<Response> login(Map<String, dynamic> data) =>
      _dio.post('/auth/login', data: data);

  Future<Response> register(Map<String, dynamic> data) =>
      _dio.post('/auth/register', data: data);

  Future<Response> sendOtp(String identifier,
          {String? deviceId}) =>
      _dio.post('/auth/send-otp', data: {
        'identifier': identifier,
        if (deviceId != null) 'device_id': deviceId,
      });

  Future<Response> verifyOtp(String identifier, String otp,
          {String? deviceId, String? deviceModel}) =>
      _dio.post('/auth/verify-otp', data: {
        'identifier': identifier,
        'otp': otp,
        if (deviceId != null) 'device_id': deviceId,
        if (deviceModel != null) 'device_model': deviceModel,
      });

  /// Silent re-login when the device was already used with this app (server-side link).
  Future<Response> restoreSession() => _dio.post('/auth/restore-session');

  Future<Response> getUser() => _dio.get('/auth/me');

  Future<Response> getMe() => _dio.get('/auth/me');

  Future<Response> logout() => _dio.post('/auth/logout');

  Future<Response> deleteAccount() => _dio.delete('/auth/account');

  Future<Response> changePassword(Map<String, dynamic> data) =>
      _dio.post('/auth/change-password', data: data);

  // ─── Config & Onboarding ─────────────────────────────────────────
  Future<Response> getConfig() => _dio.get('/config');

  Future<Response> getOnboarding() => _dio.get('/onboarding');

  // ─── Dashboard ────────────────────────────────────────────────────
  Future<Response> getDashboard() => _dio.get('/dashboard');

  // ─── Profile ──────────────────────────────────────────────────────
  Future<Response> getProfile() => _dio.get('/profile');

  Future<Response> updateProfile(Map<String, dynamic> data) =>
      _dio.put('/profile', data: data);

  Future<Response> updateAvatar(FormData data) =>
      _dio.post('/profile/avatar', data: data);

  Future<Response> deleteAvatar() => _dio.delete('/profile/avatar');

  Future<Response> getProfileCampaignEntries() =>
      _dio.get('/profile/campaign-entries');

  // ─── Stores (Merchant Locations) ──────────────────────────────────
  Future<Response> getStores({Map<String, dynamic>? params}) =>
      _dio.get('/stores', queryParameters: params);

  Future<Response> getStore(int id) => _dio.get('/stores/$id');

  Future<Response> getNearbyStores(Map<String, dynamic> params) =>
      _dio.get('/stores/nearby', queryParameters: params);

  Future<Response> getStoreCategories({Map<String, dynamic>? params}) =>
      _dio.get('/store-categories', queryParameters: params);

  Future<Response> getMerchantLocations({Map<String, dynamic>? params}) =>
      _dio.get('/stores', queryParameters: params);

  Future<Response> getStoresByCategory(int categoryId,
          {Map<String, dynamic>? params}) =>
      _dio.get('/stores',
          queryParameters: {'category_id': categoryId, ...?params});

  // ─── Campaigns ────────────────────────────────────────────────────
  Future<Response> getCampaigns({Map<String, dynamic>? params}) =>
      _dio.get('/campaigns', queryParameters: params);

  Future<Response> getCampaign(int id) => _dio.get('/campaigns/$id');

  Future<Response> getCampaignProgress(int id) =>
      _dio.get('/campaigns/$id/progress');

  Future<Response> getCampaignBounty(int id) =>
      _dio.get('/campaigns/$id/bounty');

  Future<Response> participateInCampaign(int id,
          {String mode = 'engagement'}) =>
      _dio.post('/campaigns/$id/participate');

  Future<Response> getMyCampaigns({Map<String, dynamic>? params}) =>
      _dio.get('/my-campaigns', queryParameters: params);

  // ─── Coupons ──────────────────────────────────────────────────────
  Future<Response> getCoupons({Map<String, dynamic>? params}) =>
      _dio.get('/coupons', queryParameters: params);

  Future<Response> getCoupon(int id) => _dio.get('/coupons/$id');

  /// Same as web `kutootApi.coupons.redeem` (v1).
  Future<Response> redeemCoupon(int couponId,
          [Map<String, dynamic>? data]) =>
      _dioV1.post('/coupons/$couponId/redeem', data: data);

  Future<Response> getMyCoupons({Map<String, dynamic>? params}) =>
      _dio.get('/my-coupons', queryParameters: params);

  Future<Response> calculateRedemption(Map<String, dynamic> data) =>
      _dio.post('/coupons/calculate', data: data);

  // ─── Stamps ───────────────────────────────────────────────────────
  Future<Response> getStamps({Map<String, dynamic>? params}) =>
      _dio.get('/stamps', queryParameters: params);

  Future<Response> getStampHistory({Map<String, dynamic>? params}) =>
      _dio.get('/stamps/history', queryParameters: params);

  Future<Response> reserveStamp(int campaignId) =>
      _dio.post('/stamps/reserve', data: {'campaign_id': campaignId});

  Future<Response> createStampReservationOrder(int stampId, int planId) =>
      _dio.post('/stamps/$stampId/order', data: {'plan_id': planId});

  Future<Response> confirmStampReservation(
          int stampId, Map<String, dynamic> data) =>
      _dio.post('/stamps/$stampId/confirm', data: data);

  // ─── Subscriptions ────────────────────────────────────────────────
  Future<Response> getSubscriptionPlans() => _dio.get('/subscriptions/plans');

  Future<Response> getCurrentSubscription() =>
      _dio.get('/subscriptions/current');

  Future<Response> subscribe(Map<String, dynamic> data) =>
      _dio.post('/subscriptions/subscribe', data: data);

  Future<Response> upgradeSubscription(int planId,
          {List<int>? campaignSelections}) =>
      _dio.post('/subscriptions/$planId/upgrade');

  Future<Response> verifySubscriptionPayment(Map<String, dynamic> data) =>
      _dio.post('/subscriptions/verify-payment', data: data);

  Future<Response> recordSubscriptionConsent(int planId) =>
      _dio.post('/subscriptions/$planId/consent');

  Future<Response> getAvailableCampaigns() => _dio.get('/campaigns');

  Future<Response> setPrimaryCampaign(int campaignId) =>
      _dio.post('/campaigns/$campaignId/primary');

  // ─── Transactions ───────────────────────────────────────────────
  Future<Response> getTransactions({Map<String, dynamic>? params}) =>
      _dio.get('/transactions', queryParameters: params);

  Future<Response> getTransaction(int id) => _dio.get('/transactions/$id');

  // ─── Notifications ────────────────────────────────────────────────
  Future<Response> getNotifications({Map<String, dynamic>? params}) =>
      _dio.get('/notifications', queryParameters: params);

  Future<Response> markNotificationRead(int id) =>
      _dio.post('/notifications/$id/read');

  Future<Response> markAllNotificationsRead() =>
      _dio.post('/notifications/read-all');

  Future<Response> getUnreadNotificationCount() =>
      _dio.get('/notifications/unread-count');

  // ─── Device Token (FCM) ───────────────────────────────────────────
  Future<Response> registerDeviceToken(
          {required String token, required String platform}) =>
      _dio.post('/device-tokens', data: {'token': token, 'platform': platform});

  // ─── Support Tickets ──────────────────────────────────────────────
  Future<Response> getSupportCategories() => _dio.get('/support/categories');

  Future<Response> getSupportTickets({Map<String, dynamic>? params}) =>
      _dio.get('/support/tickets', queryParameters: params);

  Future<Response> createSupportTicket(Map<String, dynamic> data) =>
      _dio.post('/support/tickets', data: data);

  Future<Response> getSupportTicket(int id) => _dio.get('/support/tickets/$id');

  Future<Response> replySupportTicket(int id, Map<String, dynamic> data) =>
      _dio.post('/support/tickets/$id/reply', data: data);

  // ─── FAQs ─────────────────────────────────────────────────────────
  Future<Response> getFaqs() => _dio.get('/faqs');

  Future<Response> getFaq(int id) => _dio.get('/faqs/$id');

  // ─── Referrals ────────────────────────────────────────────────────
  Future<Response> getReferralInfo() => _dio.get('/referral');

  Future<Response> applyReferralCode(String code) =>
      _dio.post('/referral/apply', data: {'referral_code': code});

  // ─── Payments (v1 — same as web kutootApi.coupons) ─────────────────
  Future<Response> payWithoutCoupon(Map<String, dynamic> data) =>
      _dioV1.post('/coupons/pay-without-coupon', data: data);

  Future<Response> verifyPayment(Map<String, dynamic> data) =>
      _dioV1.post('/coupons/verify-payment', data: data);

  // ─── QR Scan ──────────────────────────────────────────────────────
  Future<Response> scanQr(String qrCode) =>
      _dio.post('/qr/scan', data: {'qr_code': qrCode});

  // ─── Content (Banners, News, Partners, Deals) ─────────────────────
  Future<Response> getBanners() => _dio.get('/banners');

  Future<Response> getMarketingBanners({Map<String, dynamic>? params}) =>
      _dio.get('/banners', queryParameters: params);

  Future<Response> getStoreBanners({Map<String, dynamic>? params}) =>
      _dio.get('/banners', queryParameters: params);

  Future<Response> getFeaturedBanners({Map<String, dynamic>? params}) =>
      _dio.get('/banners', queryParameters: params);

  Future<Response> getHeroSettings({String? locale}) =>
      _dio.get('/hero-settings',
          queryParameters: locale != null ? {'locale': locale} : null);

  Future<Response> getNews() => _dio.get('/news');

  Future<Response> getNewsDetail(int id) => _dio.get('/news/$id');

  Future<Response> getPartners() => _dio.get('/partners');

  Future<Response> getDeals() => _dio.get('/deals');

  // ─── Terms & Conditions ───────────────────────────────────────────
  Future<Response> getCurrentTerms() => _dio.get('/terms/current');

  Future<Response> acceptTerms(int version) =>
      _dio.post('/terms/accept', data: {'version': version});
}
