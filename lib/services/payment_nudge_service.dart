import 'package:shared_preferences/shared_preferences.dart';

/// Gentle reminders to pay via Kutoot (savings + daily reward draw).
/// Throttled so we "poke" without feeling spammy.
class PaymentNudgeService {
  static const _prefix = 'payment_nudge_';
  static const _lastSnackMs = '${_prefix}last_snack_ms';
  static const _snackDay = '${_prefix}snack_day';
  static const _snackCount = '${_prefix}snack_count';
  static const _bannerDismissedMs = '${_prefix}banner_dismissed_ms';

  static const _minSnackGapMs = 90 * 60 * 1000; // 90 minutes
  static const _maxSnacksPerDay = 4;
  static const _bannerCooldownMs = 20 * 60 * 60 * 1000; // 20 hours

  static int _dayNumber(DateTime d) => d.year * 1000 + d.difference(
        DateTime(d.year, 1, 1),
      ).inDays;

  /// Non-null message if a snackbar may be shown now.
  static Future<String?> nextSnackMessageIfDue() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = _dayNumber(now);
    final storedDay = prefs.getInt(_snackDay) ?? 0;
    var count = prefs.getInt(_snackCount) ?? 0;
    if (storedDay != today) {
      count = 0;
      await prefs.setInt(_snackDay, today);
      await prefs.setInt(_snackCount, 0);
    }
    if (count >= _maxSnacksPerDay) return null;

    final last = prefs.getInt(_lastSnackMs) ?? 0;
    if (now.millisecondsSinceEpoch - last < _minSnackGapMs) return null;

    await prefs.setInt(_lastSnackMs, now.millisecondsSinceEpoch);
    await prefs.setInt(_snackCount, count + 1);

    return 'Pay with Kutoot at the counter — unlock savings & your daily reward chance.';
  }

  static Future<bool> shouldShowBanner() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getInt(_bannerDismissedMs) ?? 0;
    return DateTime.now().millisecondsSinceEpoch - dismissed > _bannerCooldownMs;
  }

  static Future<void> dismissBannerForCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _bannerDismissedMs,
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
