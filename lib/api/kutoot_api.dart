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
  Future<Response> login(Map<String, dynamic> data) =>
      _dio.post('/auth/login', data: data);

  Future<Response> register(Map<String, dynamic> data) =>
      _dio.post('/auth/register', data: data);

  Future<Response> forgotPassword(String email) =>
      _dio.post('/auth/forgot-password', data: {'email': email});

  Future<Response> sendOtp(String identifier) =>
      _dio.post('/auth/send-otp', data: {'identifier': identifier});

  Future<Response> getDevOtp(String identifier) =>
      _dio.get('/auth/dev-otp', queryParameters: {'identifier': identifier});

  Future<Response> verifyOtp(String mobile, String otp) =>
      _dio.post('/auth/verify-otp', data: {'mobile': mobile, 'otp': otp});

  Future<Response> resetPassword(Map<String, dynamic> data) =>
      _dio.post('/auth/reset-password', data: data);

  Future<Response> socialLogin(Map<String, dynamic> data) =>
      _dio.post('/auth/social-login', data: data);

  Future<Response> getMe() => _dio.get('/auth/me');

  Future<Response> getUser() => _dio.get('/auth/me');

  Future<Response> logout() => _dio.post('/auth/logout');

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

  // ─── Stores (Merchant Locations) ──────────────────────────────────
  Future<Response> getStores({Map<String, dynamic>? params}) =>
      _dio.get('/stores', queryParameters: params);

  Future<Response> getStore(int id) => _dio.get('/stores/$id');

  Future<Response> getNearbyStores(Map<String, dynamic> params) =>
      _dio.get('/stores/nearby', queryParameters: params);

  Future<Response> getStoreCategories() => _dio.get('/store-categories');

  Future<Response> getMerchantLocations({Map<String, dynamic>? params}) =>
      _dio.get('/stores', queryParameters: params);

  Future<Response> getStoresByCategory(int categoryId, {Map<String, dynamic>? params}) =>
      _dio.get('/stores', queryParameters: {'category_id': categoryId, ...?params});

  // ─── Campaigns (Rewards) ──────────────────────────────────────────
  Future<Response> getCampaigns({Map<String, dynamic>? params}) =>
      _dio.get('/campaigns', queryParameters: params);

  Future<Response> getCampaign(int id) => _dio.get('/campaigns/$id');

  Future<Response> getCampaignProgress(int id) => _dio.get('/campaigns/$id/progress');

  Future<Response> getMyCampaigns({Map<String, dynamic>? params}) =>
      _dio.get('/my-campaigns', queryParameters: params);

  Future<Response> getCampaignBounty(int id) => _dio.get('/campaigns/$id/bounty');

  Future<Response> participateInCampaign(int id) =>
      _dio.post('/campaigns/$id/participate');

  // ─── Stamps ───────────────────────────────────────────────────────
  Future<Response> getStamps({Map<String, dynamic>? params}) =>
      _dio.get('/stamps', queryParameters: params);

  Future<Response> getStampHistory({Map<String, dynamic>? params}) =>
      _dio.get('/stamps/history', queryParameters: params);

  Future<Response> reserveStamp(int campaignId) =>
      _dio.post('/stamps/reserve', data: {'campaign_id': campaignId});

  Future<Response> createStampReservationOrder(int stampId, int planId) =>
      _dio.post('/stamps/$stampId/order', data: {'plan_id': planId});

  Future<Response> confirmStampReservation(int stampId, Map<String, dynamic> data) =>
      _dio.post('/stamps/$stampId/confirm', data: data);

  // ─── Coupons ──────────────────────────────────────────────────────
  Future<Response> getCoupons({Map<String, dynamic>? params}) =>
      _dio.get('/coupons', queryParameters: params);

  Future<Response> getCoupon(int id) => _dio.get('/coupons/$id');

  Future<Response> redeemCoupon(int couponId, [Map<String, dynamic>? data]) =>
      _dio.post('/coupons/$couponId/redeem', data: data);

  Future<Response> getMyCoupons({Map<String, dynamic>? params}) =>
      _dio.get('/my-coupons', queryParameters: params);

  // ─── Subscriptions ────────────────────────────────────────────────
  Future<Response> getSubscriptionPlans() => _dio.get('/subscriptions/plans');

  Future<Response> getCurrentSubscription() => _dio.get('/subscriptions/current');

  Future<Response> subscribe(Map<String, dynamic> data) =>
      _dio.post('/subscriptions/subscribe', data: data);

  Future<Response> verifySubscriptionPayment(Map<String, dynamic> data) =>
      _dio.post('/subscriptions/verify-payment', data: data);

  Future<Response> recordSubscriptionConsent(int planId) =>
      _dio.post('/subscriptions/$planId/consent');

  Future<Response> upgradeSubscription(int planId) =>
      _dio.post('/subscriptions/$planId/upgrade');

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

  // ─── Payments ─────────────────────────────────────────────────────
  Future<Response> payWithoutCoupon(Map<String, dynamic> data) =>
      _dio.post('/payments/pay', data: data);

  Future<Response> verifyPayment(Map<String, dynamic> data) =>
      _dio.post('/payments/verify', data: data);

  // ─── Profile ──────────────────────────────────────────────────────
  Future<Response> getProfileCampaignEntries() =>
      _dio.get('/profile/campaign-entries');

  // ─── QR Scan ──────────────────────────────────────────────────────
  Future<Response> scanQr(String qrCode) =>
      _dio.post('/qr/scan', data: {'qr_code': qrCode});

  // ─── Content (Banners, News, Partners, Deals) ─────────────────────
  Future<Response> getBanners() => _dio.get('/banners');

  Future<Response> getFeaturedBanners() => _dio.get('/banners');

  Future<Response> getMarketingBanners() => _dio.get('/banners');

  Future<Response> getStoreBanners() => _dio.get('/banners');

  Future<Response> getNews() => _dio.get('/news');

  Future<Response> getNewsDetail(int id) => _dio.get('/news/$id');

  Future<Response> getPartners() => _dio.get('/partners');

  Future<Response> getDeals() => _dio.get('/deals');

  // ─── Terms & Conditions ───────────────────────────────────────────
  Future<Response> getCurrentTerms() => _dio.get('/terms/current');

  Future<Response> acceptTerms(int version) =>
      _dio.post('/terms/accept', data: {'version': version});

    // ─── Mobile Resource APIs ───────────────────────────────────────
    Future<Response> getAdminFaqCategories({Map<String, dynamic>? params}) =>
      _dio.get('/faq-categories', queryParameters: params);

    Future<Response> getAdminFaqCategory(int id) =>
      _dio.get('/faq-categories/$id');

    Future<Response> createAdminFaqCategory(Map<String, dynamic> data) =>
      _dio.post('/faq-categories', data: data);

    Future<Response> updateAdminFaqCategory(int id, Map<String, dynamic> data) =>
      _dio.put('/faq-categories/$id', data: data);

    Future<Response> deleteAdminFaqCategory(int id) =>
      _dio.delete('/faq-categories/$id');

    Future<Response> getAdminFaqs({Map<String, dynamic>? params}) =>
      _dio.get('/faqs', queryParameters: params);

    Future<Response> getAdminFaq(int id) => _dio.get('/faqs/$id');

    Future<Response> createAdminFaq(Map<String, dynamic> data) =>
      _dio.post('/faqs', data: data);

    Future<Response> updateAdminFaq(int id, Map<String, dynamic> data) =>
      _dio.put('/faqs/$id', data: data);

    Future<Response> deleteAdminFaq(int id) => _dio.delete('/faqs/$id');

    Future<Response> getAdminNotifications({Map<String, dynamic>? params}) =>
      _dio.get('/notifications', queryParameters: params);

    Future<Response> getAdminNotification(int id) =>
      _dio.get('/notifications/$id');

    Future<Response> createAdminNotification(Map<String, dynamic> data) =>
      _dio.post('/notifications', data: data);

    Future<Response> broadcastAdminNotification(Map<String, dynamic> data) =>
      _dio.post('/notifications/broadcast', data: data);

    Future<Response> deleteAdminNotification(int id) =>
      _dio.delete('/notifications/$id');

    Future<Response> getAdminSupportTicketCategories({Map<String, dynamic>? params}) =>
      _dio.get('/support-ticket-categories', queryParameters: params);

    Future<Response> getAdminSupportTicketCategory(int id) =>
      _dio.get('/support-ticket-categories/$id');

    Future<Response> createAdminSupportTicketCategory(Map<String, dynamic> data) =>
      _dio.post('/support-ticket-categories', data: data);

    Future<Response> updateAdminSupportTicketCategory(int id, Map<String, dynamic> data) =>
      _dio.put('/support-ticket-categories/$id', data: data);

    Future<Response> deleteAdminSupportTicketCategory(int id) =>
      _dio.delete('/support-ticket-categories/$id');

    Future<Response> getAdminSupportTickets({Map<String, dynamic>? params}) =>
      _dio.get('/support-tickets', queryParameters: params);

    Future<Response> getAdminSupportTicket(int id) =>
      _dio.get('/support-tickets/$id');

    Future<Response> updateAdminSupportTicket(int id, Map<String, dynamic> data) =>
      _dio.put('/support-tickets/$id', data: data);

    Future<Response> replyAdminSupportTicket(int id, Map<String, dynamic> data) =>
      _dio.post('/support-tickets/$id/reply', data: data);

    Future<Response> deleteAdminSupportTicket(int id) =>
      _dio.delete('/support-tickets/$id');

    Future<Response> getAdminOnboardingPages({Map<String, dynamic>? params}) =>
      _dio.get('/onboarding-pages', queryParameters: params);

    Future<Response> getAdminOnboardingPage(int id) =>
      _dio.get('/onboarding-pages/$id');

    Future<Response> createAdminOnboardingPage(FormData data) =>
      _dio.post('/onboarding-pages', data: data);

    Future<Response> updateAdminOnboardingPage(int id, FormData data) =>
        _dio.put('/onboarding-pages/$id', data: data);

    Future<Response> reorderAdminOnboardingPages(List<Map<String, dynamic>> pages) =>
      _dio.post('/onboarding-pages/reorder', data: {'pages': pages});

    Future<Response> deleteAdminOnboardingPage(int id) =>
      _dio.delete('/onboarding-pages/$id');

    Future<Response> getAdminReferrals({Map<String, dynamic>? params}) =>
      _dio.get('/referrals', queryParameters: params);

    Future<Response> getAdminReferral(int id) => _dio.get('/referrals/$id');

    Future<Response> getAdminAppConfigs({Map<String, dynamic>? params}) =>
      _dio.get('/app-configs', queryParameters: params);

    Future<Response> getAdminAppConfig(int id) => _dio.get('/app-configs/$id');

    Future<Response> createAdminAppConfig(Map<String, dynamic> data) =>
      _dio.post('/app-configs', data: data);

    Future<Response> updateAdminAppConfig(int id, Map<String, dynamic> data) =>
      _dio.put('/app-configs/$id', data: data);

    Future<Response> deleteAdminAppConfig(int id) =>
      _dio.delete('/app-configs/$id');
}
