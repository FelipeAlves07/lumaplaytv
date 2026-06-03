import '../domain/live_channel.dart';

class M3uParser {
  static List<LiveChannel> parse(String content) {
    final lines = content.split('\n');

    final channels = <LiveChannel>[];

    String currentName = '';
    String currentCategory = 'Geral';
    String currentLogo = '';

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.startsWith('#EXTINF')) {
        final categoryMatch =
            RegExp(r'group-title="([^"]*)"').firstMatch(line);

        final logoMatch = RegExp(r'tvg-logo="([^"]*)"').firstMatch(line);

        final commaIndex = line.lastIndexOf(',');

        if (commaIndex != -1) {
          currentName = line.substring(commaIndex + 1).trim();
        }

        currentLogo = logoMatch?.group(1) ?? '';

        final categoryFromM3u = categoryMatch?.group(1)?.trim() ?? '';

        if (categoryFromM3u.isNotEmpty) {
          currentCategory = categoryFromM3u;
        } else {
          currentCategory = _detectCategory(currentName);
        }
      }

      if (line.startsWith('http')) {
        channels.add(
          LiveChannel(
            name: currentName,
            category: currentCategory,
            logoUrl: currentLogo,
            streamUrl: line,
          ),
        );
      }
    }

    return channels;
  }

  static String _detectCategory(String name) {
    final value = name.toLowerCase();

    if (value.contains('sport') ||
        value.contains('espn') ||
        value.contains('premiere') ||
        value.contains('combate') ||
        value.contains('futebol') ||
        value.contains('ufc')) {
      return 'Esportes';
    }

    if (value.contains('news') ||
        value.contains('notícia') ||
        value.contains('noticias') ||
        value.contains('cnn') ||
        value.contains('jovem pan') ||
        value.contains('record news') ||
        value.contains('band news')) {
      return 'Notícias';
    }

    if (value.contains('kids') ||
        value.contains('infantil') ||
        value.contains('cartoon') ||
        value.contains('disney') ||
        value.contains('nick') ||
        value.contains('gloob')) {
      return 'Infantil';
    }

    if (value.contains('movie') ||
        value.contains('cine') ||
        value.contains('filme') ||
        value.contains('telecine') ||
        value.contains('hbo') ||
        value.contains('megapix')) {
      return 'Filmes';
    }

    if (value.contains('document') ||
        value.contains('discovery') ||
        value.contains('history') ||
        value.contains('national geographic') ||
        value.contains('nat geo')) {
      return 'Documentários';
    }

    if (value.contains('music') ||
        value.contains('música') ||
        value.contains('musica') ||
        value.contains('mtv')) {
      return 'Música';
    }

    if (value.contains('24/7') || value.contains('24h')) {
      return '24/7';
    }

    return 'Geral';
  }
}