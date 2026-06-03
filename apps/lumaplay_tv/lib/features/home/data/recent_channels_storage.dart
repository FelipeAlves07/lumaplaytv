import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class RecentChannelsStorage {
  static const _key = 'recent_live_channels';

  Future<void> saveChannel({
    required String id,
    required String title,
    required String category,
    required String poster,
    required String logoUrl,
    required String streamUrl,
  }) async {
    if (streamUrl.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? [];

    existing.removeWhere((item) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        return map['streamUrl'] == streamUrl || map['id'] == id;
      } catch (_) {
        return true;
      }
    });

    existing.insert(
      0,
      jsonEncode({
        'id': id,
        'title': title,
        'category': category,
        'poster': poster,
        'logoUrl': logoUrl,
        'streamUrl': streamUrl,
      }),
    );

    if (existing.length > 10) {
      existing.removeRange(10, existing.length);
    }

    await prefs.setStringList(_key, existing);
  }

  Future<List<Map<String, dynamic>>> getChannels() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];

    return list
        .map((item) {
          try {
            return jsonDecode(item) as Map<String, dynamic>;
          } catch (_) {
            return <String, dynamic>{};
          }
        })
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
