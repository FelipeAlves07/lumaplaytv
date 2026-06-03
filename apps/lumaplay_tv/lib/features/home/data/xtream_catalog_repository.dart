import 'package:dio/dio.dart';

import '../../../../core/constants/app_config.dart';
import '../../../../core/storage/secure_storage.dart';
import '../domain/xtream_category.dart';
import '../domain/xtream_media.dart';

class XtreamCatalogRepository {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  final SecureStorage _storage = SecureStorage();

  Future<List<XtreamCategory>> getMovieCategories() async {
    final customerId = await _storage.getUserId();

    if (customerId == null || customerId.isEmpty) {
      return [];
    }

    try {
      final response = await _dio.get('/xtream/movie-categories/$customerId');

      final data = response.data;

      if (data is! List) return [];

      return data
          .whereType<Map<String, dynamic>>()
          .map(XtreamCategory.fromJson)
          .where((category) => category.id.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<XtreamCategory>> getSeriesCategories() async {
    final customerId = await _storage.getUserId();

    if (customerId == null || customerId.isEmpty) {
      return [];
    }

    try {
      final response = await _dio.get('/xtream/series-categories/$customerId');

      final data = response.data;

      if (data is! List) return [];

      return data
          .whereType<Map<String, dynamic>>()
          .map(XtreamCategory.fromJson)
          .where((category) => category.id.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<XtreamMedia>> getMovies() async {
    final customerId = await _storage.getUserId();

    if (customerId == null || customerId.isEmpty) {
      return [];
    }

    try {
      final results = await Future.wait([
        _dio.get('/xtream/movie-categories/$customerId'),
        _dio.get('/xtream/movies/$customerId'),
      ]);

      final categoriesData = results[0].data;
      final moviesData = results[1].data;

      final categoryMap = <String, String>{};

      if (categoriesData is List) {
        for (final item in categoriesData.whereType<Map<String, dynamic>>()) {
          final category = XtreamCategory.fromJson(item);

          if (category.id.isNotEmpty) {
            categoryMap[category.id] = category.name;
          }
        }
      }

      if (moviesData is! List) return [];

      return moviesData
          .whereType<Map<String, dynamic>>()
          .map((json) => XtreamMedia.fromJson(
                json,
                categories: categoryMap,
              ))
          .where((item) => item.id.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<XtreamMedia>> getSeries() async {
    final customerId = await _storage.getUserId();

    if (customerId == null || customerId.isEmpty) {
      return [];
    }

    try {
      final results = await Future.wait([
        _dio.get('/xtream/series-categories/$customerId'),
        _dio.get('/xtream/series/$customerId'),
      ]);

      final categoriesData = results[0].data;
      final seriesData = results[1].data;

      final categoryMap = <String, String>{};

      if (categoriesData is List) {
        for (final item in categoriesData.whereType<Map<String, dynamic>>()) {
          final category = XtreamCategory.fromJson(item);

          if (category.id.isNotEmpty) {
            categoryMap[category.id] = category.name;
          }
        }
      }

      if (seriesData is! List) return [];

      return seriesData
          .whereType<Map<String, dynamic>>()
          .map((json) => XtreamMedia.fromJson(
                json,
                categories: categoryMap,
              ))
          .where((item) => item.id.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
