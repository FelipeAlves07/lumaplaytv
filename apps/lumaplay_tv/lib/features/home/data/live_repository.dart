import 'package:dio/dio.dart';

import '../../../../core/constants/app_config.dart';
import '../../../../core/storage/secure_storage.dart';
import '../domain/live_category.dart';
import '../domain/live_channel.dart';
import 'demo_m3u.dart';
import 'm3u_parser.dart';

class LiveRepository {
  final Dio _dio = Dio();
  final SecureStorage _storage = SecureStorage();

  Future<List<LiveChannel>> getChannels() async {
    final savedM3uUrl = await _storage.getM3uUrl();

    final url = savedM3uUrl != null && savedM3uUrl.trim().isNotEmpty
        ? savedM3uUrl.trim()
        : AppConfig.remoteM3uUrl;

    try {
      final response = await _dio.get(
        url,
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: true,
          receiveTimeout: const Duration(seconds: 35),
          sendTimeout: const Duration(seconds: 20),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 10; LumaPlayTV) AppleWebKit/537.36',
            'Accept': '*/*',
          },
          validateStatus: (status) {
            return status != null && status >= 200 && status < 400;
          },
        ),
      );

      final data = response.data?.toString() ?? '';

      if (data.trim().isEmpty || !data.contains('#EXTM3U')) {
        return M3uParser.parse(demoM3u);
      }

      final channels = M3uParser.parse(data);

      if (channels.isEmpty) {
        return M3uParser.parse(demoM3u);
      }

      return channels;
    } catch (_) {
      return M3uParser.parse(demoM3u);
    }
  }

  Future<List<LiveCategory>> getCategories() async {
    final channels = await getChannels();

    final counter = <String, int>{};

    for (final channel in channels) {
      counter[channel.category] = (counter[channel.category] ?? 0) + 1;
    }

    final categories = counter.entries
        .map(
          (entry) => LiveCategory(
            name: entry.key,
            total: entry.value,
          ),
        )
        .toList();

    categories.sort((a, b) => a.name.compareTo(b.name));

    return [
      LiveCategory(
        name: 'Todos',
        total: channels.length,
      ),
      ...categories,
    ];
  }
}
