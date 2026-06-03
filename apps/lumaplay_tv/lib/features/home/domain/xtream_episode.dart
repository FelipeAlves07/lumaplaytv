class XtreamEpisode {
  final String id;
  final String title;
  final String season;
  final String episodeNumber;
  final String streamUrl;
  final String duration;
  final String plot;
  final String poster;

  const XtreamEpisode({
    required this.id,
    required this.title,
    required this.season,
    required this.episodeNumber,
    required this.streamUrl,
    required this.duration,
    required this.plot,
    required this.poster,
  });

  factory XtreamEpisode.fromJson(
    Map<String, dynamic> json, {
    required String season,
  }) {
    final info = json['info'];

    String duration = '';
    String plot = '';
    String poster = '';

    if (info is Map<String, dynamic>) {
      duration = info['duration']?.toString() ?? '';
      plot = info['plot']?.toString() ?? '';
      poster = info['movie_image']?.toString() ??
          info['cover']?.toString() ??
          '';
    }

    return XtreamEpisode(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ??
          json['name']?.toString() ??
          'Episódio',
      season: season,
      episodeNumber: json['episode_num']?.toString() ?? '',
      streamUrl: json['streamUrl']?.toString() ?? '',
      duration: duration,
      plot: plot,
      poster: poster,
    );
  }
}

class XtreamSeriesInfo {
  final String title;
  final String cover;
  final String plot;
  final Map<String, List<XtreamEpisode>> seasons;

  const XtreamSeriesInfo({
    required this.title,
    required this.cover,
    required this.plot,
    required this.seasons,
  });

  factory XtreamSeriesInfo.fromJson(Map<String, dynamic> json) {
    final info = json['info'];

    String title = 'Série';
    String cover = '';
    String plot = '';

    if (info is Map<String, dynamic>) {
      title = info['name']?.toString() ??
          info['title']?.toString() ??
          'Série';
      cover = info['cover']?.toString() ??
          info['cover_big']?.toString() ??
          '';
      plot = info['plot']?.toString() ?? '';
    }

    final episodesRaw = json['episodes'];
    final seasons = <String, List<XtreamEpisode>>{};

    if (episodesRaw is Map<String, dynamic>) {
      for (final entry in episodesRaw.entries) {
        final season = entry.key;
        final value = entry.value;

        if (value is List) {
          seasons[season] = value
              .whereType<Map<String, dynamic>>()
              .map(
                (episode) => XtreamEpisode.fromJson(
                  episode,
                  season: season,
                ),
              )
              .where((episode) => episode.streamUrl.isNotEmpty)
              .toList();
        }
      }
    }

    return XtreamSeriesInfo(
      title: title,
      cover: cover,
      plot: plot,
      seasons: seasons,
    );
  }
}
