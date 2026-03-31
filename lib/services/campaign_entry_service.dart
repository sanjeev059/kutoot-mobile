import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CampaignEntryService {
  static const String _entriesKey = 'kutoot_campaign_entries';
  static const int _maxEntries = 50;

  static Future<void> addEntry({
    required int? campaignId,
    required String campaignName,
    required int stampsEarned,
    required String storeName,
    required double billAmount,
    String? imageUrl,
    int? stampTarget,
    int? progressPercent,
    String? tag,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_entriesKey) ?? <String>[];

    final entry = <String, dynamic>{
      'campaign_id': campaignId,
      'campaign_name': campaignName,
      'stamps_earned': stampsEarned,
      'store_name': storeName,
      'bill_amount': billAmount,
      'image_url': imageUrl,
      'stamp_target': stampTarget,
      'progress_percent': progressPercent,
      'tag': tag,
      'created_at': DateTime.now().toIso8601String(),
    };

    existing.insert(0, jsonEncode(entry));
    if (existing.length > _maxEntries) {
      existing.removeRange(_maxEntries, existing.length);
    }
    await prefs.setStringList(_entriesKey, existing);
  }

  static Future<List<Map<String, dynamic>>> getEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_entriesKey) ?? <String>[];
    final items = <Map<String, dynamic>>[];

    for (final row in raw) {
      try {
        final decoded = jsonDecode(row);
        if (decoded is Map) {
          items.add(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {
        // Ignore malformed rows.
      }
    }
    return items;
  }
}
