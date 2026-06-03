import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_config.dart';
import '../../../../core/storage/secure_storage.dart';

class FavoritesStorage {
  static const _key = 'favorite_items';

  final SecureStorage _storage = SecureStorage();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 12),
    ),
  );

  Future<String?> _customerId() async {
    final id = await _storage.getUserId();

    if (id == null || id.trim().isEmpty) {
      return null;
    }

    return id;
  }

  Future<List<Map<String, dynamic>>> _getLocalItems() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];

    final items = <Map<String, dynamic>>[];

    for (final raw in list) {
      try {
        final decoded = jsonDecode(raw);

        if (decoded is Map<String, dynamic>) {
          items.add(decoded);
        }
      } catch (_) {
        // Ignora registros inválidos.
      }
    }

    return items;
  }

  Future<void> _saveLocalItems(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _key,
      items.map(jsonEncode).toList(),
    );
  }

  Future<List<Map<String, dynamic>>> getItems() async {
    final customerId = await _customerId();

    if (customerId != null) {
      try {
        final response = await _dio.get('/library/$customerId/favorites');

        final data = response.data;

        if (data is List) {
          final remoteItems = data
              .whereType<Map<String, dynamic>>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();

          await _saveLocalItems(remoteItems);

          return remoteItems;
        }
      } catch (_) {
        // Fallback local.
      }
    }

    return _getLocalItems();
  }

  Future<void> toggleItem(Map<String, dynamic> item) async {
    final itemId = item['id']?.toString() ?? '';

    if (itemId.isEmpty) return;

    final customerId = await _customerId();

    if (customerId != null) {
      try {
        await _dio.post(
          '/library/$customerId/favorites/$itemId/toggle',
          data: item,
        );

        final updated = await getItems();
        await _saveLocalItems(updated);

        return;
      } catch (_) {
        // Fallback local.
      }
    }

    final list = await _getLocalItems();

    var removed = false;

    list.removeWhere((current) {
      if (current['id']?.toString() == itemId) {
        removed = true;
        return true;
      }

      return false;
    });

    if (!removed) {
      list.insert(0, item);
    }

    await _saveLocalItems(list);
  }

  Future<bool> isFavorite(String id) async {
    final items = await getItems();
    return items.any((item) => item['id']?.toString() == id);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
