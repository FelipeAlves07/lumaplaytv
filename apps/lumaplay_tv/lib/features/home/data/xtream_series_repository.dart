import 'package:dio/dio.dart';

import '../../../../core/constants/app_config.dart';
import '../../../../core/storage/secure_storage.dart';
import '../domain/xtream_episode.dart';

class XtreamSeriesRepository {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  final SecureStorage _storage = SecureStorage();

  Future<XtreamSeriesInfo?> getSeriesInfo(String seriesId) async {
    final customerId = await _storage.getUserId();

    if (customerId == null || customerId.isEmpty || seriesId.isEmpty) {
      return null;
    }

    try {
      final response = await _dio.get(
        '/xtream/series-info/$customerId/$seriesId',
      );

      final data = response.data;

      if (data is! Map<String, dynamic>) return null;

      return XtreamSeriesInfo.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}
