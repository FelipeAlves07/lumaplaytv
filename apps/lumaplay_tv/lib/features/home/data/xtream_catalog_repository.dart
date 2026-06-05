import 'package:dio/dio.dart';

import '../../../../core/storage/secure_storage.dart';
import '../domain/xtream_category.dart';
import '../domain/xtream_media.dart';

class XtreamCatalogRepository {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 25),
      receiveTimeout: const Duration(seconds: 45),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 10; LumaPlayTV) AppleWebKit/537.36',
        'Accept': '*/*',
      },
    ),
  );

  final SecureStorage _storage = SecureStorage();

  String _cleanHost(String host) {
    return host.endsWith('/') ? host.substring(0, host.length - 1) : host;
  }

  Future<_XtreamCredentials?> _credentials() async {
    final host = (await _storage.getIptvHost())?.trim() ?? '';
    final username = (await _storage.getIptvUsername())?.trim() ?? '';
    final password = (await _storage.getIptvPassword())?.trim() ?? '';

    if (host.isNotEmpty && username.isNotEmpty && password.isNotEmpty) {
      return _XtreamCredentials(
        host: _cleanHost(host),
        username: username,
        password: password,
      );
    }

    final m3uUrl = (await _storage.getM3uUrl())?.trim() ?? '';
    final uri = Uri.tryParse(m3uUrl);

    if (uri == null) return null;

    final parsedUsername = uri.queryParameters['username'] ?? '';
    final parsedPassword = uri.queryParameters['password'] ?? '';

    if (parsedUsername.isEmpty || parsedPassword.isEmpty) return null;

    return _XtreamCredentials(
      host: '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}',
      username: parsedUsername,
      password: parsedPassword,
    );
  }

  Uri _apiUrl(
    _XtreamCredentials credentials, {
    String? action,
    Map<String, String> extraParams = const {},
  }) {
    final uri = Uri.parse('${credentials.host}/player_api.php');

    return uri.replace(
      queryParameters: {
        'username': credentials.username,
        'password': credentials.password,
        if (action != null && action.isNotEmpty) 'action': action,
        ...extraParams,
      },
    );
  }

  String _movieUrl({
    required _XtreamCredentials credentials,
    required String streamId,
    required String extension,
  }) {
    return '${credentials.host}/movie/'
        '${Uri.encodeComponent(credentials.username)}/'
        '${Uri.encodeComponent(credentials.password)}/'
        '$streamId.${extension.isEmpty ? 'mp4' : extension}';
  }

  Future<dynamic> _fetch({
    String? action,
    Map<String, String> extraParams = const {},
  }) async {
    final credentials = await _credentials();

    if (credentials == null) return null;

    final response = await _dio.getUri(
      _apiUrl(
        credentials,
        action: action,
        extraParams: extraParams,
      ),
      options: Options(
        followRedirects: true,
        validateStatus: (status) {
          return status != null && status >= 200 && status < 400;
        },
      ),
    );

    return response.data;
  }

  Future<List<XtreamCategory>> getMovieCategories() async {
    try {
      final data = await _fetch(action: 'get_vod_categories');

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
    try {
      final data = await _fetch(action: 'get_series_categories');

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
    try {
      final credentials = await _credentials();

      if (credentials == null) return [];

      final results = await Future.wait([
        _fetch(action: 'get_vod_categories'),
        _fetch(action: 'get_vod_streams'),
      ]);

      final categoriesData = results[0];
      final moviesData = results[1];

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
          .map((json) {
            final streamId = json['stream_id']?.toString() ?? '';
            final extension =
                json['container_extension']?.toString().trim() ?? 'mp4';

            return XtreamMedia.fromJson(
              {
                ...json,
                'streamUrl': streamId.isEmpty
                    ? ''
                    : _movieUrl(
                        credentials: credentials,
                        streamId: streamId,
                        extension: extension,
                      ),
              },
              categories: categoryMap,
            );
          })
          .where((item) => item.id.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<XtreamMedia>> getSeries() async {
    try {
      final results = await Future.wait([
        _fetch(action: 'get_series_categories'),
        _fetch(action: 'get_series'),
      ]);

      final categoriesData = results[0];
      final seriesData = results[1];

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

class _XtreamCredentials {
  final String host;
  final String username;
  final String password;

  const _XtreamCredentials({
    required this.host,
    required this.username,
    required this.password,
  });
}
