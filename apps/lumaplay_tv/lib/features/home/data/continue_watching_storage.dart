import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/app_config.dart';
import '../../../../core/storage/secure_storage.dart';

class ContinueWatchingStorage {
  static const _storage = FlutterSecureStorage();

  static const _key = 'continue_watching_items';
  static const _limit = 50;

  final SecureStorage _secureStorage = SecureStorage();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 12),
    ),
  );

  Future<String?> _customerId() async {
    final id = await _secureStorage.getUserId();

    if (id == null || id.trim().isEmpty) {
      return null;
    }

    return id;
  }

  Future<List<Map<String, dynamic>>> _getLocalItems() async {
    final raw = await _storage.read(key: _key);

    if (raw == null || raw.trim().isEmpty) {
      return [];
    }

    try {
      final data = jsonDecode(raw);

      if (data is! List) return [];

      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveLocalItems(List<Map<String, dynamic>> items) async {
    await _storage.write(
      key: _key,
      value: jsonEncode(items.take(_limit).toList()),
    );
  }

  Future<List<Map<String, dynamic>>> getItems() async {
    final customerId = await _customerId();

    if (customerId != null) {
      try {
        final response = await _dio.get('/library/$customerId/progress');

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

  Future<int> getResumeSeconds(String id) async {
    final items = await getItems();

    final found = items.where((item) {
      return item['id']?.toString() == id;
    }).toList();

    if (found.isEmpty) return 0;

    final position = int.tryParse(
          found.first['positionSeconds']?.toString() ?? '0',
        ) ??
        0;

    final duration = int.tryParse(
          found.first['durationSeconds']?.toString() ?? '0',
        ) ??
        0;

    if (duration > 0 && position >= duration - 30) {
      return 0;
    }

    if (position < 10) return 0;

    return position;
  }

  Future<void> saveItem(
    Map<String, dynamic> item, {
    required int positionSeconds,
    required int durationSeconds,
  }) async {
    final id = item['id']?.toString() ?? '';

    if (id.isEmpty) return;

    final nextItem = {
      ...item,
      'positionSeconds': positionSeconds,
      'durationSeconds': durationSeconds,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    final customerId = await _customerId();

    if (customerId != null) {
      try {
        await _dio.post(
          '/library/$customerId/progress',
          data: nextItem,
        );
      } catch (_) {
        // Continua salvando local.
      }
    }

    final items = await _getLocalItems();

    final nextItems = [
      nextItem,
      ...items.where((current) => current['id']?.toString() != id),
    ].take(_limit).toList();

    await _saveLocalItems(nextItems);
  }

  Future<void> removeItem(String id) async {
    final customerId = await _customerId();

    if (customerId != null) {
      try {
        await _dio.delete('/library/$customerId/progress/$id');
      } catch (_) {
        // Fallback local.
      }
    }

    final items = await _getLocalItems();

    final nextItems = items.where((item) {
      return item['id']?.toString() != id;
    }).toList();

    await _saveLocalItems(nextItems);
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}
