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

  String _cleanHost(String host) {
    final value = host.trim();
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  Future<List<String>> _candidateUrls() async {
    final urls = <String>[];

    final savedM3uUrl = (await _storage.getM3uUrl())?.trim() ?? '';

    if (savedM3uUrl.isNotEmpty) {
      urls.add(savedM3uUrl);
    }

    final host = _cleanHost((await _storage.getIptvHost())?.trim() ?? '');
    final username = (await _storage.getIptvUsername())?.trim() ?? '';
    final password = (await _storage.getIptvPassword())?.trim() ?? '';

    if (host.isNotEmpty && username.isNotEmpty && password.isNotEmpty) {
      final encodedUser = Uri.encodeQueryComponent(username);
      final encodedPass = Uri.encodeQueryComponent(password);

      urls.addAll([
        '$host/get.php?username=$encodedUser&password=$encodedPass&type=m3u_plus&output=mpegts',
        '$host/get.php?username=$encodedUser&password=$encodedPass&type=m3u_plus&output=ts',
        '$host/get.php?username=$encodedUser&password=$encodedPass&type=m3u_plus&output=hls',
      ]);
    }

    if (urls.isEmpty && AppConfig.remoteM3uUrl.trim().isNotEmpty) {
      urls.add(AppConfig.remoteM3uUrl.trim());
    }

    return urls.toSet().toList();
  }

  Future<List<LiveChannel>> getChannels() async {
    final urls = await _candidateUrls();

    if (urls.isEmpty) {
      return M3uParser.parse(demoM3u);
    }

    for (final url in urls) {
      try {
        final response = await _dio.get(
          url,
          options: Options(
            responseType: ResponseType.plain,
            followRedirects: true,
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 30),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Linux; Android 10; LumaPlayTV) AppleWebKit/537.36 Chrome/120 Mobile Safari/537.36',
              'Accept': '*/*',
              'Connection': 'keep-alive',
            },
            validateStatus: (status) {
              return status != null && status >= 200 && status < 400;
            },
          ),
        );

        final data = response.data?.toString() ?? '';

        if (data.trim().isEmpty || !data.contains('#EXTM3U')) {
          continue;
        }

        final channels = M3uParser.parse(data);

        if (channels.isNotEmpty) {
          return channels;
        }
      } catch (_) {
        continue;
      }
    }

    // Se existe uma playlist real vinculada mas ela falhou, não mostramos canais demo,
    // para evitar confundir o usuário com conteúdo falso.
    final hasRealPlaylist = urls.any((url) => url.contains('get.php'));

    if (hasRealPlaylist) {
      return [];
    }

    return M3uParser.parse(demoM3u);
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
