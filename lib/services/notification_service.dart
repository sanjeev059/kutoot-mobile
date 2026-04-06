import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../api/kutoot_api.dart';
import '../screens/campaigns/campaign_detail_screen.dart';
import '../screens/campaigns/campaigns_screen.dart';
import '../screens/home/kinetic_home_screens.dart';
import '../screens/rewards/rewards_deals_screen.dart';
import '../screens/stores/stores_screen.dart';
import '../screens/notifications/notifications_screen.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _api = KutootApi();
  final _messaging = FirebaseMessaging.instance;
  Timer? _pollTimer;

  GlobalKey<NavigatorState>? _navigatorKey;
  String _cityName = 'Bengaluru';

  int _unreadCount = 0;
  List<NotificationItem> _notifications = [];
  bool _loading = false;
  String? _fcmToken;

  int get unreadCount => _unreadCount;
  List<NotificationItem> get notifications => _notifications;
  bool get loading => _loading;
  String? get fcmToken => _fcmToken;

  static const List<String> _topics = [
    'all_users',
    'offers',
    'new_stores',
    'coupons',
    'bank_offers',
    'plans',
    'campaigns',
  ];

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  void setCityName(String city) {
    _cityName = city;
  }

  Future<void> initFCM() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('FCM auth status: ${settings.authorizationStatus}');

    _fcmToken = await _messaging.getToken();
    debugPrint('FCM Token: $_fcmToken');

    if (_fcmToken != null) {
      _registerTokenWithBackend(_fcmToken!);
    }

    _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      _registerTokenWithBackend(token);
    });

    for (final topic in _topics) {
      await _messaging.subscribeToTopic(topic);
    }
    debugPrint('Subscribed to FCM topics: $_topics');

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(const Duration(seconds: 2), () {
        _handleMessageTap(initialMessage);
      });
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground FCM: ${message.notification?.title}');

    final notification = message.notification;
    if (notification != null) {
      final item = NotificationItem(
        id: message.hashCode,
        title: notification.title ?? 'Notification',
        body: notification.body ?? '',
        type: _extractType(message.data),
        actionData: Map<String, dynamic>.from(message.data),
        isRead: false,
        createdAt: DateTime.now().toIso8601String(),
      );
      _notifications.insert(0, item);
      _unreadCount++;
      notifyListeners();
    }
  }

  void _handleMessageTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');
    final type = _extractType(message.data);
    final data = Map<String, dynamic>.from(message.data);
    navigateToScreen(type, data);
    fetchNotifications();
  }

  String _extractType(Map<String, dynamic> data) {
    if (data.containsKey('type')) return data['type'].toString();
    final actionData = data['action_data'];
    if (actionData is Map && actionData.containsKey('type')) {
      return actionData['type'].toString();
    }
    return 'general';
  }

  void navigateToScreen(String type, Map<String, dynamic> data) {
    final nav = _navigatorKey?.currentState;
    if (nav == null) {
      debugPrint('Navigator not available for notification deep link');
      return;
    }

    debugPrint('Navigating for notification type: $type, data: $data');

    Widget? screen;

    switch (type) {
      case 'campaign':
        final campaignId = _parseInt(data['campaign_id']);
        if (campaignId != null) {
          screen = CampaignDetailScreen(campaignId: campaignId);
        } else {
          screen = CampaignsScreen(cityName: _cityName);
        }
        break;

      case 'new_store':
        screen = const StoresScreen();
        break;

      case 'coupon':
        screen = RewardsDealsScreen(cityName: _cityName);
        break;

      case 'plan':
      case 'plan_update':
        screen = LoggedInHomeScreen(cityName: _cityName);
        break;

      default:
        screen = const NotificationsScreen();
        break;
    }

    nav.push(MaterialPageRoute(builder: (_) => screen!));
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  Future<void> _registerTokenWithBackend(String token) async {
    try {
      await _api.registerDeviceToken(token: token, platform: 'android');
      debugPrint('FCM token registered with backend');
    } catch (e) {
      debugPrint('Failed to register FCM token: $e');
    }
  }

  void startPolling() {
    _pollTimer?.cancel();
    fetchUnreadCount();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => fetchUnreadCount(),
    );
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> fetchUnreadCount() async {
    try {
      final res = await _api.getUnreadNotificationCount();
      final data = res.data;
      if (data is Map) {
        _unreadCount = data['count'] is int
            ? data['count'] as int
            : int.tryParse(data['count']?.toString() ?? '0') ?? 0;
      } else if (data is int) {
        _unreadCount = data;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchNotifications() async {
    _loading = true;
    notifyListeners();
    try {
      final res = await _api.getNotifications(params: {'per_page': 50});
      final data = res.data;
      List items = [];
      if (data is Map && data['data'] is List) {
        items = data['data'] as List;
      } else if (data is List) {
        items = data;
      }

      _notifications = items.map<NotificationItem>((item) {
        final m = item is Map
            ? Map<String, dynamic>.from(item)
            : <String, dynamic>{};

        final actionData = m['action_data'] is Map
            ? Map<String, dynamic>.from(m['action_data'])
            : <String, dynamic>{};

        final navType = m['action_type']?.toString() ??
            actionData['type']?.toString() ??
            m['type']?.toString() ??
            'general';

        return NotificationItem(
          id: m['id'] is int
              ? m['id'] as int
              : int.tryParse(m['id']?.toString() ?? '0') ?? 0,
          title: m['title']?.toString() ??
              m['data']?['title']?.toString() ??
              'Notification',
          body: m['body']?.toString() ??
              m['data']?['body']?.toString() ??
              m['message']?.toString() ??
              '',
          type: navType,
          actionData: actionData,
          isRead: m['read_at'] != null,
          createdAt: m['created_at']?.toString() ?? '',
        );
      }).toList();

      _unreadCount = _notifications.where((n) => !n.isRead).length;
      _loading = false;
      notifyListeners();
    } catch (_) {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await _api.markNotificationRead(id);
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx >= 0) {
        _notifications[idx] = _notifications[idx].copyWith(isRead: true);
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _api.markAllNotificationsRead();
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }
}

class NotificationItem {
  final int id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> actionData;
  final bool isRead;
  final String createdAt;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.actionData = const {},
    this.isRead = false,
    this.createdAt = '',
  });

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id,
        title: title,
        body: body,
        type: type,
        actionData: actionData,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  IconData get icon {
    switch (type) {
      case 'payment':
        return Icons.payment;
      case 'stamp':
        return Icons.stars_rounded;
      case 'coupon':
        return Icons.local_offer_rounded;
      case 'campaign':
        return Icons.campaign_rounded;
      case 'plan':
      case 'plan_update':
        return Icons.workspace_premium_rounded;
      case 'new_store':
        return Icons.store_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String get timeAgo {
    if (createdAt.isEmpty) return '';
    try {
      final dt = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
