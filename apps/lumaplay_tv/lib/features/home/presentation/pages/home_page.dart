import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'live_player_page.dart';
import 'series_details_page.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/app_config.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/live_repository.dart';
import '../../data/favorites_storage.dart';
import '../../data/recent_channels_storage.dart';
import '../../data/continue_watching_storage.dart';
import '../../data/preferences_storage.dart';
import '../../data/xtream_catalog_repository.dart';
import '../../domain/live_category.dart';
import '../../domain/xtream_media.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _ContentItem {
  final String id;
  final String title;
  final String subtitle;
  final String tag;
  final String year;
  final String duration;
  final String description;
  final IconData icon;
  final String poster;
  final String logoUrl;
  final List<Color> colors;

  final String? streamUrl;
  final bool isLive;
  final String category;

  const _ContentItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.year,
    required this.duration,
    required this.description,
    required this.icon,
    required this.poster,
    required this.colors,
    this.logoUrl = '',
    this.streamUrl,
    this.isLive = false,
    this.category = 'Geral',
  });
}

class HomePageContentData {
  static const demoVideoUrl =
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';
}

class _HomePageState extends State<HomePage> {
  final storage = SecureStorage();
  final liveRepository = LiveRepository();
  final catalogRepository = XtreamCatalogRepository();
  final recentStorage = RecentChannelsStorage();
  final continueWatchingStorage = ContinueWatchingStorage();
  final preferencesStorage = PreferencesStorage();
  final favoritesStorage = FavoritesStorage();

  final tmdbDio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 12),
    ),
  );

  final accountDio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
    ),
  );

  int selectedMenu = 0;

  _ContentItem? detailItem;
  _ContentItem? playerItem;
  late _ContentItem selectedHero;

  VideoPlayerController? videoController;
  Timer? videoControlsTimer;
  bool videoLoading = false;
  bool videoError = false;
  bool videoControlsVisible = true;

  bool liveLoading = true;
  bool catalogLoading = true;
  bool sidebarVisible = false;
  int visibleMovies = 20;
  int visibleSeries = 20;
  List<_ContentItem> liveChannels = [];
  List<_ContentItem> filteredLiveChannels = [];
  List<_ContentItem> recentChannels = [];
  List<_ContentItem> continueWatchingItems = [];
  List<_ContentItem> favoriteItems = [];
  Set<String> favoriteIds = {};
  Map<String, String> itemSynopses = {};
  Set<String> loadingSynopses = {};
  List<String> tmdbTrendingMovies = [];
  List<String> tmdbTrendingSeries = [];
  bool tmdbTrendingLoaded = false;
  List<String> preferredCategories = [];
  bool preferencesOnboardingCompleted = false;
  bool preferencesOnboardingLoaded = false;
  Set<String> onboardingMovieIds = {};
  Set<String> onboardingSeriesIds = {};

  final TextEditingController liveSearchController = TextEditingController();
  final TextEditingController movieSearchController = TextEditingController();
  final TextEditingController seriesSearchController = TextEditingController();
  String liveSearchQuery = '';
  String movieSearchQuery = '';
  String seriesSearchQuery = '';
  String selectedMovieCategory = 'Todos';
  String selectedSeriesCategory = 'Todos';
  List<LiveCategory> liveCategories = const [
    LiveCategory(name: 'Todos', total: 0),
  ];
  String selectedLiveCategory = 'Todos';

  final menus = const [
    'Home',
    'Filmes',
    'Séries',
    'TV Ao Vivo',
    'Favoritos',
    'Configurações',
    'Sair',
  ];

  final icons = const [
    Icons.home_rounded,
    Icons.movie_creation_rounded,
    Icons.tv_rounded,
    Icons.live_tv_rounded,
    Icons.favorite_rounded,
    Icons.settings_rounded,
    Icons.logout_rounded,
  ];

  List<_ContentItem> movies = const [
    _ContentItem(
      id: 'movie_interstellar',
      title: 'Interstellar',
      subtitle: 'Ficção científica em 4K',
      tag: 'SCI-FI',
      year: '2014',
      duration: '2h 49min',
      description:
          'Uma jornada épica pelo espaço, tempo e esperança da humanidade em busca de um novo lar entre as estrelas.',
      icon: Icons.auto_awesome_rounded,
      poster: 'assets/images/posters/interstellar.jpg',
      colors: [Color(0xFF123A72), Color(0xFF08111F)],
      streamUrl: HomePageContentData.demoVideoUrl,
    ),
    _ContentItem(
      id: 'movie_batman',
      title: 'Batman',
      subtitle: 'Ação sombria premium',
      tag: 'AÇÃO',
      year: '2022',
      duration: '2h 56min',
      description:
          'Um vigilante sombrio enfrenta o crime e mergulha nos segredos mais perigosos de uma cidade tomada pela corrupção.',
      icon: Icons.dark_mode_rounded,
      poster: 'assets/images/posters/batman.jpg',
      colors: [Color(0xFF4B1A78), Color(0xFF12061C)],
      streamUrl: HomePageContentData.demoVideoUrl,
    ),
    _ContentItem(
      id: 'movie_duna',
      title: 'Duna',
      subtitle: 'Aventura épica HDR',
      tag: 'HDR',
      year: '2021',
      duration: '2h 35min',
      description:
          'Em um planeta desértico, famílias poderosas disputam controle, destino e sobrevivência em uma guerra monumental.',
      icon: Icons.landscape_rounded,
      poster: 'assets/images/posters/duna.jpg',
      colors: [Color(0xFF8B470C), Color(0xFF1A0A02)],
      streamUrl: HomePageContentData.demoVideoUrl,
    ),
    _ContentItem(
      id: 'movie_john_wick',
      title: 'John Wick',
      subtitle: 'Ação intensa em HD',
      tag: 'HD',
      year: '2019',
      duration: '2h 10min',
      description:
          'Um assassino lendário retorna ao submundo em uma sequência implacável de ação, vingança e sobrevivência.',
      icon: Icons.flash_on_rounded,
      poster: 'assets/images/posters/johnwick.jpg',
      colors: [Color(0xFF7A1220), Color(0xFF180305)],
      streamUrl: HomePageContentData.demoVideoUrl,
    ),
    _ContentItem(
      id: 'movie_stranger',
      title: 'Stranger',
      subtitle: 'Mistério sobrenatural',
      tag: 'SÉRIE',
      year: '2016',
      duration: '4 temporadas',
      description:
          'Mistérios sobrenaturais, amizade e segredos sombrios cercam uma pequena cidade marcada por eventos inexplicáveis.',
      icon: Icons.bolt_rounded,
      poster: 'assets/images/posters/stranger.jpg',
      colors: [Color(0xFF0F5465), Color(0xFF051216)],
      streamUrl: HomePageContentData.demoVideoUrl,
    ),
  ];

  List<_ContentItem> series = const [
    _ContentItem(
      id: 'series_breaking_bad',
      title: 'Breaking Bad',
      subtitle: 'Drama criminal',
      tag: 'DRAMA',
      year: '2008',
      duration: '5 temporadas',
      description:
          'Um professor de química muda drasticamente de vida ao entrar em um mundo perigoso de crime e ambição.',
      icon: Icons.local_fire_department_rounded,
      poster: 'assets/images/posters/breakingbad.jpg',
      colors: [Color(0xFF0D4A2A), Color(0xFF04120A)],
      streamUrl: HomePageContentData.demoVideoUrl,
    ),
    _ContentItem(
      id: 'series_stranger',
      title: 'Stranger',
      subtitle: 'Mistério sobrenatural',
      tag: 'SÉRIE',
      year: '2016',
      duration: '4 temporadas',
      description:
          'Uma série de eventos estranhos transforma uma cidade comum em palco de forças misteriosas e perigosas.',
      icon: Icons.bolt_rounded,
      poster: 'assets/images/posters/stranger.jpg',
      colors: [Color(0xFF421137), Color(0xFF10040D)],
      streamUrl: HomePageContentData.demoVideoUrl,
    ),
    _ContentItem(
      id: 'series_batman',
      title: 'Batman',
      subtitle: 'Coleção premium',
      tag: 'TOP',
      year: '2022',
      duration: '2h 56min',
      description:
          'A escuridão de Gotham ganha vida em uma história intensa de investigação, medo e justiça.',
      icon: Icons.dark_mode_rounded,
      poster: 'assets/images/posters/batman.jpg',
      colors: [Color(0xFF143B88), Color(0xFF050A19)],
      streamUrl: HomePageContentData.demoVideoUrl,
    ),
    _ContentItem(
      id: 'series_duna',
      title: 'Duna',
      subtitle: 'Universo expandido',
      tag: '4K',
      year: '2021',
      duration: '2h 35min',
      description:
          'Uma saga grandiosa sobre poder, profecia e sobrevivência em um mundo dominado por areia e ambição.',
      icon: Icons.landscape_rounded,
      poster: 'assets/images/posters/duna.jpg',
      colors: [Color(0xFF4A176A), Color(0xFF100419)],
      streamUrl: HomePageContentData.demoVideoUrl,
    ),
  ];

  @override
  void initState() {
    super.initState();
    selectedHero = movies.first;
    loadCatalog();
    loadLiveChannels();
    loadRecentChannels();
    loadContinueWatching();
    loadPreferredCategories();
    loadPreferenceOnboarding();
    loadFavorites();
    loadTmdbTrendingBrazil();
  }

  @override
  void dispose() {
    liveSearchController.dispose();
    movieSearchController.dispose();
    seriesSearchController.dispose();
    videoControlsTimer?.cancel();
    videoController?.dispose();
    super.dispose();
  }

  Future<void> loadCatalog() async {
    final results = await Future.wait([
      catalogRepository.getMovies(),
      catalogRepository.getSeries(),
    ]);

    final xtreamMovies = results[0];
    final xtreamSeries = results[1];

    final nextMovies = xtreamMovies
        .take(1000)
        .map(contentItemFromXtreamMovie)
        .where((item) => item.title.trim().isNotEmpty)
        .toList();

    final nextSeries = xtreamSeries
        .take(1000)
        .map(contentItemFromXtreamSeries)
        .where((item) => item.title.trim().isNotEmpty)
        .toList();

    if (!mounted) return;

    setState(() {
      if (nextMovies.isNotEmpty) {
        movies = nextMovies;
      }

      if (nextSeries.isNotEmpty) {
        series = nextSeries;
      }

      catalogLoading = false;

      if (selectedMenu == 0 || selectedMenu == 1) {
        selectedHero = movies.first;
      }

      if (selectedMenu == 2) {
        selectedHero = series.first;
      }
    });
  }

  _ContentItem contentItemFromXtreamMovie(XtreamMedia item) {
    return _ContentItem(
      id: 'movie_${item.id}',
      title: item.title,
      subtitle: 'Filme da sua lista IPTV',
      tag: 'FILME',
      year: item.year.isEmpty ? 'IPTV' : item.year,
      duration: item.rating.isEmpty ? 'Catálogo' : 'Nota ${item.rating}',
      description:
          'Sinopse carregando automaticamente. Se não aparecer, este filme foi importado da sua lista LumaPlay e pode estar sem descrição cadastrada.',
      icon: Icons.movie_creation_rounded,
      poster: item.posterUrl,
      colors: const [Color(0xFF123A72), Color(0xFF07111F)],
      streamUrl: item.streamUrl.isEmpty
          ? HomePageContentData.demoVideoUrl
          : item.streamUrl,
      category: item.categoryName.isEmpty ? 'Filmes' : item.categoryName,
    );
  }

  _ContentItem contentItemFromXtreamSeries(XtreamMedia item) {
    return _ContentItem(
      id: 'series_${item.id}',
      title: item.title,
      subtitle: 'Série da sua lista IPTV',
      tag: 'SÉRIE',
      year: item.year.isEmpty ? 'IPTV' : item.year,
      duration: 'Episódios',
      description:
          'Sinopse carregando automaticamente. Se não aparecer, esta série foi importada da sua lista LumaPlay e pode estar sem descrição cadastrada.',
      icon: Icons.tv_rounded,
      poster: item.posterUrl,
      colors: const [Color(0xFF4B1A78), Color(0xFF12061C)],
      streamUrl: null,
      category: item.categoryName.isEmpty ? 'Séries' : item.categoryName,
    );
  }

  Widget buildNoPosterCard({
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Image.asset(
      'assets/images/poster_sem_capa.png',
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.low,
      errorBuilder: (_, _, _) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF182033),
                Color(0xFF090B12),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: const Center(
            child: Icon(
              Icons.movie_creation_rounded,
              color: Colors.white54,
              size: 42,
            ),
          ),
        );
      },
    );
  }

  Widget buildBannerFallbackImage(_ContentItem item) {
    final asset = item.id.startsWith('series_')
        ? 'assets/images/banner_sem_fanart_serie.png'
        : 'assets/images/banner_sem_fanart_filme.png';

    return Image.asset(
      asset,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
      errorBuilder: (_, _, _) {
        return buildPosterImage(
          item.poster,
          fit: BoxFit.cover,
          cacheWidth: 720,
        );
      },
    );
  }

  Widget buildHeroOrFanartImage(_ContentItem item) {
    final poster = item.poster.trim();
    final isNetwork =
        poster.startsWith('http://') || poster.startsWith('https://');

    if (!isNetwork || poster.isEmpty) {
      return buildBannerFallbackImage(item);
    }

    return Image.network(
      poster,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
      errorBuilder: (_, _, _) => buildBannerFallbackImage(item),
    );
  }

  Widget buildPosterImage(
    String poster, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    int? cacheWidth,
  }) {
    final cleanPoster = poster.trim();

    if (cleanPoster.isEmpty) {
      return buildNoPosterCard(
        width: width,
        height: height,
        fit: fit,
      );
    }

    final isNetwork =
        cleanPoster.startsWith('http://') || cleanPoster.startsWith('https://');

    if (isNetwork) {
      return Image.network(
        cleanPoster,
        width: width,
        height: height,
        fit: fit,
        filterQuality: FilterQuality.low,
        errorBuilder: (_, _, _) {
          return buildNoPosterCard(
            width: width,
            height: height,
            fit: fit,
          );
        },
      );
    }

    return Image.asset(
      cleanPoster,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth,
      filterQuality: FilterQuality.low,
      errorBuilder: (_, _, _) {
        return buildNoPosterCard(
          width: width,
          height: height,
          fit: fit,
        );
      },
    );
  }

  List<String> get movieCategoryNames {
    final names = movies
        .map((item) => item.category.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();

    names.sort();

    return ['Todos', ...names];
  }

  List<String> get seriesCategoryNames {
    final names = series
        .map((item) => item.category.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();

    names.sort();

    return ['Todos', ...names];
  }

  bool hasValidPoster(_ContentItem item) {
    final poster = item.poster.trim();

    return poster.startsWith('http://') || poster.startsWith('https://');
  }

  List<_ContentItem> get moviesWithPoster {
    final withPoster = movies.where(hasValidPoster).toList();

    if (withPoster.isEmpty) {
      return movies.take(20).toList();
    }

    return withPoster;
  }

  List<_ContentItem> get seriesWithPoster {
    final withPoster = series.where(hasValidPoster).toList();

    if (withPoster.isEmpty) {
      return series.take(20).toList();
    }

    return withPoster;
  }

  List<_ContentItem> get filteredMovies {
    final query = movieSearchQuery.trim().toLowerCase();
    final source = query.isEmpty ? moviesWithPoster : movies;

    return source.where((item) {
      final matchesCategory =
          selectedMovieCategory == 'Todos' || item.category == selectedMovieCategory;

      final matchesSearch = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.year.toLowerCase().contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<_ContentItem> get filteredSeries {
    final query = seriesSearchQuery.trim().toLowerCase();
    final source = query.isEmpty ? seriesWithPoster : series;

    return source.where((item) {
      final matchesCategory =
          selectedSeriesCategory == 'Todos' || item.category == selectedSeriesCategory;

      final matchesSearch = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.year.toLowerCase().contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  void selectMovieCategory(String category) {
    setState(() {
      selectedMovieCategory = category;
      visibleMovies = 20;
    });
  }

  void selectSeriesCategory(String category) {
    setState(() {
      selectedSeriesCategory = category;
      visibleSeries = 20;
    });
  }

  void onMovieSearchChanged(String value) {
    setState(() {
      movieSearchQuery = value;
      visibleMovies = 20;
    });
  }

  void onSeriesSearchChanged(String value) {
    setState(() {
      seriesSearchQuery = value;
      visibleSeries = 20;
    });
  }

  void showMoreMovies() {
    final total = filteredMovies.length;

    setState(() {
      visibleMovies += 20;

      if (visibleMovies > total) {
        visibleMovies = total;
      }
    });
  }

  void showMoreSeries() {
    final total = filteredSeries.length;

    setState(() {
      visibleSeries += 20;

      if (visibleSeries > total) {
        visibleSeries = total;
      }
    });
  }

  Widget buildLoadMoreButton({
    required bool visible,
    required VoidCallback onPressed,
  }) {
    if (!visible) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: _TvFocus(
        onPressed: onPressed,
        childBuilder: (focused) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: focused ? 48 : 44,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: focused ? Colors.white : Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: focused ? Colors.white : Colors.white.withOpacity(0.12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.expand_more_rounded,
                  color: focused ? Colors.black : Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  'Ver mais 20',
                  style: TextStyle(
                    color: focused ? Colors.black : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildCatalogLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 14),
          Text(
            'Carregando filmes e séries da sua lista...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> loadLiveChannels() async {
    final channels = await liveRepository.getChannels();

    final items = channels.asMap().entries.map((entry) {
      final index = entry.key;
      final channel = entry.value;
      final style = liveStyleForCategory(channel.category);

      return _ContentItem(
        id: 'live_$index',
        title: channel.name,
        subtitle: channel.category,
        tag: 'AO VIVO',
        year: 'Ao vivo',
        duration: '24h',
        description:
            'Canal ao vivo importado automaticamente da sua lista M3U.',
        icon: style.icon,
        poster: style.poster,
        logoUrl: channel.logoUrl,
        colors: style.colors,
        streamUrl: channel.streamUrl,
        isLive: true,
        category: channel.category,
      );
    }).toList();

    final counter = <String, int>{};

    for (final item in items) {
      counter[item.category] = (counter[item.category] ?? 0) + 1;
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

    if (!mounted) return;

    setState(() {
      liveChannels = items;
      filteredLiveChannels = items;
      liveCategories = [
        LiveCategory(name: 'Todos', total: items.length),
        ...categories,
      ];
      liveLoading = false;

      if (selectedMenu == 3 && items.isNotEmpty) {
        selectedHero = items.first;
      }
    });
  }


  Future<void> loadRecentChannels() async {
    final items = await recentStorage.getChannels();

    final channels = items.map((item) {
      final category = item['category']?.toString() ?? 'Geral';
      final style = liveStyleForCategory(category);

      return _ContentItem(
        id: item['id']?.toString() ?? item['title']?.toString() ?? 'recent',
        title: item['title']?.toString() ?? 'Canal recente',
        subtitle: category,
        tag: 'RECENTE',
        year: 'Ao vivo',
        duration: '24h',
        description: 'Canal assistido recentemente.',
        icon: style.icon,
        poster: item['poster']?.toString() ?? style.poster,
        logoUrl: item['logoUrl']?.toString() ?? '',
        colors: style.colors,
        streamUrl: item['streamUrl']?.toString() ?? HomePageContentData.demoVideoUrl,
        isLive: true,
        category: category,
      );
    }).toList();

    if (!mounted) return;

    setState(() {
      recentChannels = channels;
    });
  }

  Future<void> loadContinueWatching() async {
    final items = await continueWatchingStorage.getItems();

    final continueItems = items.map(_contentItemFromStorage).toList();

    if (!mounted) return;

    setState(() {
      continueWatchingItems = continueItems;

      if (selectedMenu == 0 && continueItems.isNotEmpty) {
        selectedHero = continueItems.first;
      }
    });
  }

  Future<void> loadPreferredCategories() async {
    final categories = await preferencesStorage.getPreferredCategories();

    if (!mounted) return;

    setState(() {
      preferredCategories = categories;

      if (selectedMenu == 0 &&
          continueWatchingItems.isEmpty &&
          preferredCategories.isNotEmpty &&
          recommendedMovies.isNotEmpty) {
        selectedHero = recommendedMovies.first;
      }
    });
  }

  Future<void> loadPreferenceOnboarding() async {
    final completed = await preferencesStorage.hasCompletedOnboarding();

    if (!mounted) return;

    setState(() {
      preferencesOnboardingCompleted = completed;
      preferencesOnboardingLoaded = true;
    });
  }

  void toggleOnboardingMovie(_ContentItem item) {
    setState(() {
      if (onboardingMovieIds.contains(item.id)) {
        onboardingMovieIds.remove(item.id);
        return;
      }

      if (onboardingMovieIds.length >= 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Você já escolheu 5 filmes.'),
          ),
        );
        return;
      }

      onboardingMovieIds.add(item.id);
    });
  }

  void toggleOnboardingSeries(_ContentItem item) {
    setState(() {
      if (onboardingSeriesIds.contains(item.id)) {
        onboardingSeriesIds.remove(item.id);
        return;
      }

      if (onboardingSeriesIds.length >= 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Você já escolheu 5 séries.'),
          ),
        );
        return;
      }

      onboardingSeriesIds.add(item.id);
    });
  }

  Future<void> finishPreferenceOnboarding() async {
    if (onboardingMovieIds.length < 5 || onboardingSeriesIds.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escolha 5 filmes e 5 séries para continuar.'),
        ),
      );
      return;
    }

    final selectedItems = [
      ...movies.where((item) => onboardingMovieIds.contains(item.id)),
      ...series.where((item) => onboardingSeriesIds.contains(item.id)),
    ];

    final categories = selectedItems
        .map((item) => item.category.trim())
        .where((category) => category.isNotEmpty && category != 'Todos')
        .toSet()
        .toList();

    await preferencesStorage.finishOnboarding(categories);
    await loadPreferredCategories();

    if (!mounted) return;

    setState(() {
      preferencesOnboardingCompleted = true;
      preferencesOnboardingLoaded = true;
    });
  }

  Future<void> resetPreferenceOnboarding() async {
    await preferencesStorage.resetOnboarding();

    if (!mounted) return;

    setState(() {
      preferencesOnboardingCompleted = false;
      onboardingMovieIds = {};
      onboardingSeriesIds = {};
    });
  }

  Future<void> togglePreferredCategory(String category) async {
    await preferencesStorage.toggleCategory(category);
    await loadPreferredCategories();
  }


  String normalizeCatalogTitle(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'\[[^\]]*\]'), ' ')
        .replaceAll(RegExp(r'\([^\)]*\)'), ' ')
        .replaceAll(RegExp(r'\b(4k|uhd|fhd|hd|dual audio|dublado|legendado|bluray|web-dl|webrip|1080p|720p)\b'), ' ')
        .replaceAll(RegExp(r'[^a-z0-9áàâãéèêíïóôõöúçñ ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool titleLooksLikeMatch(String catalogTitle, String trendingTitle) {
    final catalog = normalizeCatalogTitle(catalogTitle);
    final trending = normalizeCatalogTitle(trendingTitle);

    if (catalog.isEmpty || trending.isEmpty) return false;

    if (catalog == trending) return true;
    if (catalog.contains(trending)) return true;
    if (trending.contains(catalog)) return true;

    final catalogWords = catalog.split(' ').where((word) => word.length >= 3).toSet();
    final trendingWords = trending.split(' ').where((word) => word.length >= 3).toSet();

    if (catalogWords.isEmpty || trendingWords.isEmpty) return false;

    final hits = catalogWords.intersection(trendingWords).length;
    final minWords = catalogWords.length < trendingWords.length
        ? catalogWords.length
        : trendingWords.length;

    return minWords >= 2 && hits >= 2;
  }

  Future<void> loadTmdbTrendingBrazil() async {
    try {
      final response = await tmdbDio.get('/tmdb/trending-brazil');
      final data = response.data;

      if (data is! Map<String, dynamic>) return;

      final movieItems = data['movies'];
      final seriesItems = data['series'];

      final movieTitles = movieItems is List
          ? movieItems
              .whereType<Map<String, dynamic>>()
              .expand((item) {
                return [
                  item['title']?.toString() ?? '',
                  item['originalTitle']?.toString() ?? '',
                ];
              })
              .where((title) => title.trim().isNotEmpty)
              .toSet()
              .toList()
          : <String>[];

      final seriesTitles = seriesItems is List
          ? seriesItems
              .whereType<Map<String, dynamic>>()
              .expand((item) {
                return [
                  item['title']?.toString() ?? '',
                  item['originalTitle']?.toString() ?? '',
                ];
              })
              .where((title) => title.trim().isNotEmpty)
              .toSet()
              .toList()
          : <String>[];

      if (!mounted) return;

      setState(() {
        tmdbTrendingMovies = movieTitles;
        tmdbTrendingSeries = seriesTitles;
        tmdbTrendingLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        tmdbTrendingLoaded = true;
      });
    }
  }

  List<_ContentItem> matchCatalogWithTrending({
    required List<_ContentItem> catalog,
    required List<String> trendingTitles,
    int limit = 20,
  }) {
    if (trendingTitles.isEmpty) return const [];

    final result = <_ContentItem>[];
    final usedIds = <String>{};

    for (final title in trendingTitles) {
      for (final item in catalog) {
        if (usedIds.contains(item.id)) continue;

        if (titleLooksLikeMatch(item.title, title)) {
          result.add(item);
          usedIds.add(item.id);
          break;
        }
      }

      if (result.length >= limit) break;
    }

    return result;
  }

  List<_ContentItem> get trendingBrazilMovies {
    final matched = matchCatalogWithTrending(
      catalog: moviesWithPoster,
      trendingTitles: tmdbTrendingMovies,
    );

    if (matched.isNotEmpty) return matched;

    return popularBrazilMovies;
  }

  List<_ContentItem> get trendingBrazilSeries {
    final matched = matchCatalogWithTrending(
      catalog: seriesWithPoster,
      trendingTitles: tmdbTrendingSeries,
    );

    if (matched.isNotEmpty) return matched;

    return popularBrazilSeries;
  }

  List<_ContentItem> get recommendedMovies {
    if (preferredCategories.isEmpty) {
      return moviesWithPoster.take(20).toList();
    }

    final preferred = moviesWithPoster.where((item) {
      return preferredCategories.contains(item.category);
    }).toList();

    if (preferred.isEmpty) {
      return movies.take(20).toList();
    }

    return preferred.take(20).toList();
  }

  List<_ContentItem> get recommendedSeries {
    if (preferredCategories.isEmpty) {
      return seriesWithPoster.take(20).toList();
    }

    final preferred = seriesWithPoster.where((item) {
      return preferredCategories.contains(item.category);
    }).toList();

    if (preferred.isEmpty) {
      return series.take(20).toList();
    }

    return preferred.take(20).toList();
  }

  static const List<String> _popularBrazilTerms = [
    'round 6',
    'squid game',
    'the last of us',
    'stranger',
    'reacher',
    'invencível',
    'invincible',
    'wandinha',
    'wednesday',
    'house of the dragon',
    'the boys',
    'bridgerton',
    'grey',
    'chicago',
    'deadpool',
    'wolverine',
    'john wick',
    'missão impossível',
    'mission impossible',
    'velozes',
    'fast',
    'furious',
    'avatar',
    'vingadores',
    'avengers',
    'homem-aranha',
    'spider',
    'batman',
    'coringa',
    'joker',
    'duna',
    'dune',
    'oppenheimer',
    'barbie',
    'godzilla',
    'kong',
    'matrix',
    'harry potter',
    'senhor dos anéis',
    'lord of the rings',
    'hobbit',
    'interestelar',
    'interstellar',
    'terror',
    'ação',
    'comédia',
    'lançamento',
    'cinema',
  ];

  int popularBrazilScore(_ContentItem item) {
    final haystack = [
      item.title,
      item.subtitle,
      item.category,
      item.tag,
      item.year,
    ].join(' ').toLowerCase();

    var score = 0;

    for (var i = 0; i < _popularBrazilTerms.length; i++) {
      final term = _popularBrazilTerms[i].toLowerCase();

      if (haystack.contains(term)) {
        score += (_popularBrazilTerms.length - i) * 10;
      }
    }

    final year = int.tryParse(item.year);

    if (year != null) {
      final now = DateTime.now().year;
      final distance = (now - year).abs();

      if (distance <= 1) score += 80;
      if (distance <= 3) score += 45;
      if (distance <= 6) score += 20;
    }

    if (item.poster.trim().startsWith('http')) score += 12;

    return score;
  }

  List<_ContentItem> get popularBrazilMovies {
    final ranked = [...moviesWithPoster];

    ranked.sort((a, b) {
      final score = popularBrazilScore(b).compareTo(popularBrazilScore(a));

      if (score != 0) return score;

      return a.title.compareTo(b.title);
    });

    return ranked.take(20).toList();
  }

  List<_ContentItem> get popularBrazilSeries {
    final ranked = [...seriesWithPoster];

    ranked.sort((a, b) {
      final score = popularBrazilScore(b).compareTo(popularBrazilScore(a));

      if (score != 0) return score;

      return a.title.compareTo(b.title);
    });

    return ranked.take(20).toList();
  }

  Future<void> loadFavorites() async {
    final items = await favoritesStorage.getItems();

    final favorites = items.map(_contentItemFromStorage).toList();
    final ids = favorites.map((item) => item.id).toSet();

    if (!mounted) return;

    setState(() {
      favoriteItems = favorites;
      favoriteIds = ids;
    });
  }

  _ContentItem _contentItemFromStorage(Map<String, dynamic> item) {
    final category = item['category']?.toString() ?? 'Geral';
    final isLive = item['isLive'] == true || item['isLive']?.toString() == 'true';
    final style = liveStyleForCategory(category);

    return _ContentItem(
      id: item['id']?.toString() ?? item['title']?.toString() ?? 'favorite',
      title: item['title']?.toString() ?? 'Favorito',
      subtitle: item['subtitle']?.toString() ?? category,
      tag: item['tag']?.toString() ?? (isLive ? 'AO VIVO' : 'FAVORITO'),
      year: item['year']?.toString() ?? (isLive ? 'Ao vivo' : ''),
      duration: item['duration']?.toString() ?? (isLive ? '24h' : ''),
      description: item['description']?.toString() ?? '',
      icon: isLive ? style.icon : Icons.favorite_rounded,
      poster: item['poster']?.toString() ?? style.poster,
      logoUrl: item['logoUrl']?.toString() ?? '',
      colors: style.colors,
      streamUrl: item['streamUrl']?.toString(),
      isLive: isLive,
      category: category,
    );
  }

  Map<String, dynamic> _contentItemToStorage(_ContentItem item) {
    return {
      'id': item.id,
      'title': item.title,
      'subtitle': item.subtitle,
      'tag': item.tag,
      'year': item.year,
      'duration': item.duration,
      'description': item.description,
      'poster': item.poster,
      'logoUrl': item.logoUrl,
      'streamUrl': item.streamUrl ?? '',
      'isLive': item.isLive,
      'category': item.category,
    };
  }

  bool isFavorite(_ContentItem item) {
    return favoriteIds.contains(item.id);
  }

  Future<void> toggleFavorite(_ContentItem item) async {
    await favoritesStorage.toggleItem(_contentItemToStorage(item));
    await loadFavorites();
  }

  void applyLiveFilters({String? category, String? query}) {
    final nextCategory = category ?? selectedLiveCategory;
    final nextQuery = query ?? liveSearchQuery;
    final normalizedQuery = nextQuery.trim().toLowerCase();

    final result = liveChannels.where((item) {
      final matchesCategory = nextCategory == 'Todos' || item.category == nextCategory;

      final matchesSearch = normalizedQuery.isEmpty ||
          item.title.toLowerCase().contains(normalizedQuery) ||
          item.category.toLowerCase().contains(normalizedQuery);

      return matchesCategory && matchesSearch;
    }).toList();

    setState(() {
      selectedLiveCategory = nextCategory;
      liveSearchQuery = nextQuery;
      filteredLiveChannels = result;

      if (result.isNotEmpty) {
        selectedHero = result.first;
      }
    });
  }

  _LiveStyle liveStyleForCategory(String category) {
    final value = category.toLowerCase();

    if (value.contains('sport') || value.contains('esporte')) {
      return const _LiveStyle(
        icon: Icons.sports_soccer_rounded,
        poster: 'assets/images/posters/johnwick.jpg',
        colors: [Color(0xFF0D4A2A), Color(0xFF04120A)],
      );
    }

    if (value.contains('not') || value.contains('news')) {
      return const _LiveStyle(
        icon: Icons.public_rounded,
        poster: 'assets/images/posters/batman.jpg',
        colors: [Color(0xFF3B1668), Color(0xFF0A0614)],
      );
    }

    if (value.contains('infantil') ||
        value.contains('kids') ||
        value.contains('child')) {
      return const _LiveStyle(
        icon: Icons.child_care_rounded,
        poster: 'assets/images/posters/stranger.jpg',
        colors: [Color(0xFF8B470C), Color(0xFF1A0A02)],
      );
    }

    if (value.contains('serie') || value.contains('série')) {
      return const _LiveStyle(
        icon: Icons.tv_rounded,
        poster: 'assets/images/posters/breakingbad.jpg',
        colors: [Color(0xFF4B1A78), Color(0xFF12061C)],
      );
    }

    return const _LiveStyle(
      icon: Icons.live_tv_rounded,
      poster: 'assets/images/posters/interstellar.jpg',
      colors: [Color(0xFF123A72), Color(0xFF07111F)],
    );
  }

  IconData categoryIcon(String category) {
    final value = category.toLowerCase();

    if (value.contains('todos')) return Icons.grid_view_rounded;

    if (value.contains('sport') || value.contains('esporte')) {
      return Icons.sports_soccer_rounded;
    }

    if (value.contains('not') || value.contains('news')) {
      return Icons.public_rounded;
    }

    if (value.contains('infantil') || value.contains('kids')) {
      return Icons.child_care_rounded;
    }

    if (value.contains('filme') || value.contains('cine')) {
      return Icons.movie_filter_rounded;
    }

    if (value.contains('document')) {
      return Icons.travel_explore_rounded;
    }

    if (value.contains('music') || value.contains('música')) {
      return Icons.music_note_rounded;
    }

    if (value.contains('24/7') || value.contains('24h')) {
      return Icons.schedule_rounded;
    }

    return Icons.live_tv_rounded;
  }

  Future<void> logout() async {
    await storage.clearSession();

    if (!mounted) return;

    context.go('/');
  }

  void onMenuTap(int index) {
    if (menus[index] == 'Sair') {
      logout();
      return;
    }

    setState(() {
      selectedMenu = index;
      detailItem = null;
      playerItem = null;

      if (index == 0 || index == 1) selectedHero = movies.first;
      if (index == 2) selectedHero = series.first;
      if (index == 3 && liveChannels.isNotEmpty) {
        selectedHero = liveChannels.first;
      }

      final compact = MediaQuery.of(context).size.width < 720;
      if (compact) {
        sidebarVisible = false;
      }
    });
  }

  void selectHero(_ContentItem item) {
    setState(() {
      selectedHero = item;
    });
  }

  void selectLiveCategory(String category) {
    applyLiveFilters(category: category);
  }

  void onLiveSearchChanged(String value) {
    applyLiveFilters(query: value);
  }

  Future<void> openSeriesEpisodes(_ContentItem item) async {
    final seriesId = item.id.replaceFirst('series_', '');

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          return SeriesDetailsPage(
            seriesId: seriesId,
            title: item.title,
            poster: item.poster,
          );
        },
      ),
    );
  }

  Future<void> openDetails(_ContentItem item) async {
    setState(() {
      selectedHero = item;
      detailItem = item;
    });

    loadSynopsisForItem(item);
  }

  void showVideoControls() {
    videoControlsTimer?.cancel();

    if (mounted) {
      setState(() {
        videoControlsVisible = true;
      });
    }

    videoControlsTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || videoLoading || videoError) return;

      setState(() {
        videoControlsVisible = false;
      });
    });
  }

  Future<void> openPlayer(_ContentItem item) async {
    if (item.isLive) {
      await recentStorage.saveChannel(
        id: item.id,
        title: item.title,
        category: item.category,
        poster: item.poster,
        logoUrl: item.logoUrl,
        streamUrl: item.streamUrl ?? '',
      );

      await loadRecentChannels();

      final sourceList = selectedMenu == 3 && filteredLiveChannels.isNotEmpty
          ? filteredLiveChannels
          : liveChannels;

      final playerItems = sourceList.map((channel) {
        return LivePlayerItem(
          title: channel.title,
          category: channel.category,
          streamUrl: channel.streamUrl ?? HomePageContentData.demoVideoUrl,
          poster: channel.poster,
          logoUrl: channel.logoUrl,
          isLive: channel.isLive,
        );
      }).toList();

      final initialIndex =
          sourceList.indexWhere((channel) => channel.id == item.id);

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) {
            return LivePlayerPage(
              items: playerItems,
              initialIndex: initialIndex < 0 ? 0 : initialIndex,
            );
          },
        ),
      );

      return;
    }

    if (item.streamUrl == null || item.streamUrl!.trim().isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Episódios da série serão adicionados no próximo bloco.'),
        ),
      );

      return;
    }

    await continueWatchingStorage.saveItem(
      _contentItemToStorage(item),
      positionSeconds: 0,
      durationSeconds: 0,
    );

    await loadContinueWatching();

    await videoController?.dispose();

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(item.streamUrl!),
    );

    controller.addListener(() {
      if (!mounted || playerItem == null) return;
      setState(() {});
    });

    setState(() {
      selectedHero = item;
      playerItem = item;
      detailItem = null;
      videoController = controller;
      videoLoading = true;
      videoError = false;
      videoControlsVisible = true;
    });

    try {
      await controller.initialize();

      final resumeSeconds = await continueWatchingStorage.getResumeSeconds(item.id);

      if (resumeSeconds > 0) {
        await controller.seekTo(Duration(seconds: resumeSeconds));
      }

      await controller.setLooping(item.isLive);
      await controller.play();

      if (!mounted) return;

      setState(() {
        videoLoading = false;
        videoError = false;
      });

      showVideoControls();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        videoLoading = false;
        videoError = true;
      });
    }
  }

  Future<void> closePlayer() async {
    final controller = videoController;
    final currentItem = playerItem;

    if (controller != null &&
        currentItem != null &&
        !currentItem.isLive &&
        controller.value.isInitialized) {
      final position = controller.value.position;
      final duration = controller.value.duration;

      await continueWatchingStorage.saveItem(
        _contentItemToStorage(currentItem),
        positionSeconds: position.inSeconds,
        durationSeconds: duration.inSeconds,
      );

      await loadContinueWatching();
    }

    setState(() {
      playerItem = null;
      videoController = null;
      videoLoading = false;
      videoError = false;
      videoControlsVisible = true;
    });

    await controller?.dispose();
  }

  Future<void> togglePlay() async {
    showVideoControls();

    final controller = videoController;

    if (controller == null || !controller.value.isInitialized) return;

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }

    if (!mounted) return;
    setState(() {});
  }

  Future<void> seekVideoBy(Duration offset) async {
    showVideoControls();

    final controller = videoController;

    if (controller == null || !controller.value.isInitialized) return;
    if (playerItem?.isLive == true) return;

    final current = controller.value.position;
    final duration = controller.value.duration;
    var next = current + offset;

    if (next < Duration.zero) {
      next = Duration.zero;
    }

    if (duration > Duration.zero && next > duration) {
      next = duration;
    }

    await controller.seekTo(next);

    if (!mounted) return;
    setState(() {});
  }

  Future<void> seekVideoTo(Duration position) async {
    showVideoControls();

    final controller = videoController;

    if (controller == null || !controller.value.isInitialized) return;
    if (playerItem?.isLive == true) return;

    final duration = controller.value.duration;
    var next = position;

    if (next < Duration.zero) {
      next = Duration.zero;
    }

    if (duration > Duration.zero && next > duration) {
      next = duration;
    }

    await controller.seekTo(next);

    if (!mounted) return;
    setState(() {});
  }

  Widget buildSidebarItem(int index) {
    final selected = selectedMenu == index;

    return _TvFocus(
      autofocus: index == 0,
      onPressed: () => onMenuTap(index),
      childBuilder: (focused) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          height: 47,
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: selected
                ? const LinearGradient(
                    colors: [
                      Color(0xFF3B82F6),
                      Color(0xFF8B5CF6),
                    ],
                  )
                : null,
            color: selected
                ? null
                : focused
                    ? const Color(0xFF1B2440)
                    : const Color(0xFF141827),
            border: Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(icons[index], color: Colors.white, size: 18),
              const SizedBox(width: 11),
              Text(
                menus[index],
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildPageHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.52),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHeroBanner() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(selectedHero.id),
        height: 190,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            fit: StackFit.expand,
            children: [
              buildHeroOrFanartImage(selectedHero),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0.94),
                      Colors.black.withOpacity(0.66),
                      Colors.black.withOpacity(0.18),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF3B82F6),
                            Color(0xFF8B5CF6),
                            Color(0xFFEC4899),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedHero.isLive ? 'AO VIVO AGORA' : 'DESTAQUE',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            selectedHero.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 35,
                              height: 1,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            selectedHero.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.78),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    _TvFocus(
                      onPressed: () => openDetails(selectedHero),
                      childBuilder: (focused) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          height: focused ? 44 : 40,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: Colors.white,
                            border: Border.all(
                              color: focused
                                  ? const Color(0xFF8B5CF6)
                                  : Colors.transparent,
                              width: focused ? 2 : 0,
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: Colors.black,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Detalhes',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSectionTitle(String title, String action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Text(
            action,
            style: TextStyle(
              color: Colors.white.withOpacity(0.42),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPosterCard(_ContentItem item) {
    final selected = selectedHero.id == item.id;

    return _TvFocus(
      onFocus: () => selectHero(item),
      onPressed: () => openDetails(item),
      childBuilder: (focused) {
        final active = focused || selected;

        return Container(
          width: 142,
          margin: const EdgeInsets.only(right: 14),
          padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 170),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: active
                          ? Colors.white
                          : Colors.white.withOpacity(0.08),
                      width: active ? 2 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: buildPosterImage(
                      item.poster,
                      fit: BoxFit.cover,
                      cacheWidth: 210,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white70,
                  fontSize: active ? 14 : 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildMovieRow({
    required String title,
    required List<_ContentItem> items,
    String action = 'VER TUDO',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionTitle(title, action),
        SizedBox(
          height: 205,
          child: ListView.builder(
            clipBehavior: Clip.hardEdge,
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              return buildPosterCard(items[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget buildCatalogSearchBox({
    required TextEditingController controller,
    required String hintText,
    required ValueChanged<String> onChanged,
    required VoidCallback onClear,
  }) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: Colors.white.withOpacity(0.72),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (controller.text.trim().isNotEmpty)
            _TvFocus(
              onPressed: onClear,
              childBuilder: (focused) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: focused ? 34 : 30,
                  height: focused ? 34 : 30,
                  decoration: BoxDecoration(
                    color: focused
                        ? Colors.white.withOpacity(0.18)
                        : Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: focused ? Colors.white : Colors.transparent,
                    ),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget buildCatalogCategoryChips({
    required List<String> categories,
    required String selectedCategory,
    required ValueChanged<String> onSelected,
  }) {
    if (categories.length <= 1) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _TvFocus(
              onPressed: () => onSelected(category),
              childBuilder: (focused) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: focused ? 48 : 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                            colors: [
                              Color(0xFF3B82F6),
                              Color(0xFF8B5CF6),
                            ],
                          )
                        : null,
                    color: selected
                        ? null
                        : focused
                            ? Colors.white.withOpacity(0.14)
                            : Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget buildPosterGrid({
    required List<_ContentItem> items,
  }) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: const Text(
          'Nenhum item encontrado.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width < 520
            ? 2
            : width < 760
                ? 3
                : width < 1050
                    ? 4
                    : 6;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          clipBehavior: Clip.hardEdge,
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 18,
            childAspectRatio: 0.60,
          ),
          itemBuilder: (context, index) {
            return buildPosterGridCard(items[index]);
          },
        );
      },
    );
  }

  Widget buildPosterGridCard(_ContentItem item) {
    final selected = selectedHero.id == item.id;

    return _TvFocus(
      onFocus: () => selectHero(item),
      onPressed: () => openDetails(item),
      childBuilder: (focused) {
        final active = focused || selected;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: active ? Colors.white : Colors.white.withOpacity(0.08),
              width: active ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: buildPosterImage(
                    item.poster,
                    fit: BoxFit.cover,
                    cacheWidth: 260,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white70,
                  fontSize: active ? 13 : 12,
                  height: 1.12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildEmptyContinueWatching() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF3B82F6),
                  Color(0xFF8B5CF6),
                ],
              ),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Continue assistindo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Quando você começar um filme ou episódio, ele aparece aqui para retomar depois.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.62),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHomePageContent() {
    final homeMovies = moviesWithPoster.take(20).toList();
    final homeSeries = seriesWithPoster.take(20).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildHeroBanner(),
        const SizedBox(height: 22),
        if (catalogLoading) ...[
          buildCatalogLoading(),
          const SizedBox(height: 18),
        ],
        if (continueWatchingItems.isNotEmpty) ...[
          buildMovieRow(
            title: 'Continue assistindo',
            items: continueWatchingItems.take(20).toList(),
            action: '${continueWatchingItems.length} ITENS',
          ),
          const SizedBox(height: 14),
        ] else ...[
          buildEmptyContinueWatching(),
          const SizedBox(height: 14),
        ],
        buildMovieRow(
          title: 'Em alta no Brasil',
          items: trendingBrazilMovies,
          action: '${popularBrazilMovies.length} FILMES',
        ),
        const SizedBox(height: 14),
        buildMovieRow(
          title: 'Séries em alta',
          items: trendingBrazilSeries,
          action: '${popularBrazilSeries.length} SÉRIES',
        ),
        const SizedBox(height: 14),
        if (preferredCategories.isNotEmpty) ...[
          buildMovieRow(
            title: 'Recomendado para você',
            items: recommendedMovies,
            action: '${preferredCategories.length} GOSTOS',
          ),
          const SizedBox(height: 14),
          buildMovieRow(
            title: 'Séries recomendadas',
            items: recommendedSeries,
            action: '${recommendedSeries.length} SÉRIES',
          ),
          const SizedBox(height: 14),
        ],
        buildMovieRow(
          title: 'Filmes da sua lista',
          items: homeMovies,
          action: '${homeMovies.length}/${moviesWithPoster.length} FILMES',
        ),
        const SizedBox(height: 14),
        buildMovieRow(
          title: 'Séries da sua lista',
          items: homeSeries,
          action: '${homeSeries.length}/${seriesWithPoster.length} SÉRIES',
        ),
      ],
    );
  }

  Widget buildMoviesPageContent() {
    final results = filteredMovies;
    final visibleItems = results.take(visibleMovies).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildPageHeader(
          'Filmes',
          'Catálogo real importado da sua lista Xtream.',
        ),
        buildCatalogCategoryChips(
          categories: movieCategoryNames,
          selectedCategory: selectedMovieCategory,
          onSelected: selectMovieCategory,
        ),
        const SizedBox(height: 12),
        buildCatalogSearchBox(
          controller: movieSearchController,
          hintText: 'Buscar filme por nome, ano ou categoria...',
          onChanged: onMovieSearchChanged,
          onClear: () {
            movieSearchController.clear();
            onMovieSearchChanged('');
          },
        ),
        const SizedBox(height: 18),
        if (catalogLoading) ...[
          buildCatalogLoading(),
          const SizedBox(height: 18),
        ],
        buildSectionTitle(
          selectedMovieCategory == 'Todos' ? 'Filmes da sua lista' : selectedMovieCategory,
          '${visibleItems.length}/${results.length} FILMES',
        ),
        buildPosterGrid(items: visibleItems),
        buildLoadMoreButton(
          visible: visibleMovies < results.length,
          onPressed: showMoreMovies,
        ),
      ],
    );
  }

  Widget buildSeriesPageContent() {
    final results = filteredSeries;
    final visibleItems = results.take(visibleSeries).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildPageHeader(
          'Séries',
          'Catálogo real importado da sua lista Xtream.',
        ),
        buildCatalogCategoryChips(
          categories: seriesCategoryNames,
          selectedCategory: selectedSeriesCategory,
          onSelected: selectSeriesCategory,
        ),
        const SizedBox(height: 12),
        buildCatalogSearchBox(
          controller: seriesSearchController,
          hintText: 'Buscar série por nome, ano ou categoria...',
          onChanged: onSeriesSearchChanged,
          onClear: () {
            seriesSearchController.clear();
            onSeriesSearchChanged('');
          },
        ),
        const SizedBox(height: 18),
        if (catalogLoading) ...[
          buildCatalogLoading(),
          const SizedBox(height: 18),
        ],
        buildSectionTitle(
          selectedSeriesCategory == 'Todos' ? 'Séries da sua lista' : selectedSeriesCategory,
          '${visibleItems.length}/${results.length} SÉRIES',
        ),
        buildPosterGrid(items: visibleItems),
        buildLoadMoreButton(
          visible: visibleSeries < results.length,
          onPressed: showMoreSeries,
        ),
      ],
    );
  }

  Widget buildLiveChannelCard(_ContentItem item) {
    final selected = selectedHero.id == item.id;

    return _TvFocus(
      onFocus: () => selectHero(item),
      onPressed: () => openDetails(item),
      childBuilder: (focused) {
        final active = focused || selected;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          width: double.infinity,
          margin: EdgeInsets.zero,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: active ? Colors.white : Colors.white.withOpacity(0.08),
              width: active ? 2 : 1,
            ),
            gradient: LinearGradient(colors: item.colors),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                buildPosterImage(
                  item.poster,
                  fit: BoxFit.cover,
                  cacheWidth: 360,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black.withOpacity(0.76),
                        Colors.black.withOpacity(0.42),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  top: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE11D48),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
                if (isFavorite(item))
                  Positioned(
                    right: 14,
                    top: 14,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.48),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFE11D48),
                        size: 16,
                      ),
                    ),
                  ),
                Center(
                  child: item.logoUrl.isNotEmpty
                      ? Image.network(
                          item.logoUrl,
                          width: 74,
                          height: 54,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) {
                            return Icon(
                              item.icon,
                              color: Colors.white,
                              size: 44,
                            );
                          },
                        )
                      : Icon(
                          item.icon,
                          color: Colors.white,
                          size: 44,
                        ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.72),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildLiveCategoryChip(LiveCategory category) {
    final selected = selectedLiveCategory == category.name;

    return _TvFocus(
      onPressed: () => selectLiveCategory(category.name),
      childBuilder: (focused) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: focused ? 56 : 50,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [
                      Color(0xFF3B82F6),
                      Color(0xFF8B5CF6),
                    ],
                  )
                : null,
            color: selected ? null : Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: focused ? Colors.white : Colors.white.withOpacity(0.08),
              width: focused ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                categoryIcon(category.name),
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 170),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${category.total} canais',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.68),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget buildLiveSearchBox() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: Colors.white.withOpacity(0.72),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: liveSearchController,
              onChanged: onLiveSearchChanged,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Buscar canal por nome ou categoria...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (liveSearchQuery.trim().isNotEmpty)
            _TvFocus(
              onPressed: () {
                liveSearchController.clear();
                onLiveSearchChanged('');
              },
              childBuilder: (focused) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: focused ? 34 : 30,
                  height: focused ? 34 : 30,
                  decoration: BoxDecoration(
                    color: focused
                        ? Colors.white.withOpacity(0.18)
                        : Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: focused ? Colors.white : Colors.transparent,
                    ),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget buildLiveContent() {
    if (liveLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildPageHeader(
            'TV Ao Vivo',
            'Carregando categorias e canais da lista M3U.',
          ),
          const SizedBox(height: 80),
          const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ],
      );
    }

    if (liveChannels.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildPageHeader(
            'TV Ao Vivo',
            'Nenhum canal encontrado na lista M3U.',
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text(
              'Verifique o arquivo demo_m3u.dart ou a origem da sua lista M3U.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildPageHeader(
          'TV Ao Vivo',
          'Canais importados automaticamente da sua lista M3U.',
        ),
        buildHeroBanner(),
        const SizedBox(height: 18),
        SizedBox(
          height: 62,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: liveCategories.length,
            itemBuilder: (context, index) {
              return buildLiveCategoryChip(liveCategories[index]);
            },
          ),
        ),
        const SizedBox(height: 16),
        buildLiveSearchBox(),
        const SizedBox(height: 22),
        buildSectionTitle(
          liveSearchQuery.trim().isNotEmpty
              ? 'Resultado da busca'
              : selectedLiveCategory == 'Todos'
                  ? 'Canais em destaque'
                  : selectedLiveCategory,
          '${filteredLiveChannels.length} CANAIS',
        ),
        filteredLiveChannels.isEmpty
            ? SizedBox(
                height: 145,
                child: Center(
                  child: Text(
                    'Nenhum canal encontrado.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.62),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                clipBehavior: Clip.hardEdge,
                itemCount: filteredLiveChannels.take(60).length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 280,
                  mainAxisExtent: 145,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                ),
                itemBuilder: (context, index) {
                  return buildLiveChannelCard(filteredLiveChannels[index]);
                },
              ),
        const SizedBox(height: 18),
        if (recentChannels.isNotEmpty) ...[
          buildSectionTitle(
            'Últimos canais assistidos',
            '${recentChannels.length} CANAIS',
          ),
          SizedBox(
            height: 145,
            child: ListView.builder(
              clipBehavior: Clip.hardEdge,
              scrollDirection: Axis.horizontal,
              itemCount: recentChannels.length,
              itemBuilder: (context, index) {
                return buildLiveChannelCard(recentChannels[index]);
              },
            ),
          ),
          const SizedBox(height: 18),
        ],
        if (favoriteItems.where((item) => item.isLive).isNotEmpty) ...[
          buildSectionTitle(
            'Favoritos ao vivo',
            '${favoriteItems.where((item) => item.isLive).length} CANAIS',
          ),
          SizedBox(
            height: 145,
            child: ListView(
              clipBehavior: Clip.hardEdge,
              scrollDirection: Axis.horizontal,
              children: favoriteItems
                  .where((item) => item.isLive)
                  .map(buildLiveChannelCard)
                  .toList(),
            ),
          ),
          const SizedBox(height: 18),
        ],
        buildMovieRow(
          title: 'Programação recomendada',
          items: movies.take(20).toList(),
          action: 'AGORA',
        ),
      ],
    );
  }

  Widget buildFavoritesPageContent() {
    final liveFavorites = favoriteItems.where((item) => item.isLive).toList();
    final catalogFavorites = favoriteItems.where((item) => !item.isLive).toList();

    if (favoriteItems.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildPageHeader(
            'Favoritos',
            'Sua lista pessoal de filmes, séries e canais salvos.',
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Image.asset(
              'assets/images/favoritos_vazio.png',
              width: double.infinity,
              height: 360,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              errorBuilder: (_, _, _) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: const Text(
                    'Você ainda não adicionou favoritos. Abra os detalhes de um filme, série ou canal e clique em Favoritar.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildPageHeader(
          'Favoritos',
          'Sua lista pessoal de filmes, séries e canais salvos.',
        ),
        if (liveFavorites.isNotEmpty) ...[
          buildSectionTitle('Canais favoritos', '${liveFavorites.length} CANAIS'),
          SizedBox(
            height: 145,
            child: ListView.builder(
              clipBehavior: Clip.hardEdge,
              scrollDirection: Axis.horizontal,
              itemCount: liveFavorites.length,
              itemBuilder: (context, index) {
                return buildLiveChannelCard(liveFavorites[index]);
              },
            ),
          ),
          const SizedBox(height: 18),
        ],
        if (catalogFavorites.isNotEmpty)
          buildMovieRow(
            title: 'Filmes e séries favoritos',
            items: catalogFavorites,
            action: '${catalogFavorites.length} ITENS',
          ),
      ],
    );
  }

  Widget buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.58),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPreferenceChip(String category) {
    final selected = preferredCategories.contains(category);

    return _TvFocus(
      onPressed: () => togglePreferredCategory(category),
      childBuilder: (focused) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: focused ? 48 : 44,
          margin: const EdgeInsets.only(right: 10, bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [
                      Color(0xFF3B82F6),
                      Color(0xFF8B5CF6),
                    ],
                  )
                : null,
            color: selected
                ? null
                : focused
                    ? Colors.white.withOpacity(0.16)
                    : Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: focused ? Colors.white : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.check_circle_rounded : Icons.add_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 7),
              Text(
                category,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildPreferencesSection() {
    final categories = [
      ...movieCategoryNames,
      ...seriesCategoryNames,
    ]
        .where((category) => category != 'Todos')
        .toSet()
        .take(30)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gostos do usuário',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            preferredCategories.isEmpty
                ? 'Selecione algumas categorias para melhorar as recomendações.'
                : '${preferredCategories.length} categorias selecionadas.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.62),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            children: categories.map(buildPreferenceChip).toList(),
          ),
        ],
      ),
    );
  }

  Widget buildHistorySection() {
    if (continueWatchingItems.isEmpty && recentChannels.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: const Text(
          'Histórico vazio. Quando você assistir canais, filmes ou episódios, eles aparecem aqui.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.45,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (continueWatchingItems.isNotEmpty) ...[
          buildMovieRow(
            title: 'Continue assistindo',
            items: continueWatchingItems.take(20).toList(),
            action: '${continueWatchingItems.length} ITENS',
          ),
          const SizedBox(height: 16),
        ],
        if (recentChannels.isNotEmpty) ...[
          buildSectionTitle(
            'Últimos canais assistidos',
            '${recentChannels.length} CANAIS',
          ),
          SizedBox(
            height: 145,
            child: ListView.builder(
              clipBehavior: Clip.hardEdge,
              scrollDirection: Axis.horizontal,
              itemCount: recentChannels.length,
              itemBuilder: (context, index) {
                return buildLiveChannelCard(recentChannels[index]);
              },
            ),
          ),
        ],
      ],
    );
  }


  DateTime? parseAccountDate(String value) {
    if (value.trim().isEmpty) return null;

    return DateTime.tryParse(value);
  }

  String formatAccountDate(String value) {
    final parsed = parseAccountDate(value);

    if (parsed == null) return 'Não informado';

    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();

    return '$day/$month/$year';
  }

  int? daysUntilExpiration(String value) {
    final parsed = parseAccountDate(value);

    if (parsed == null) return null;

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final expirationOnly = DateTime(parsed.year, parsed.month, parsed.day);

    return expirationOnly.difference(todayOnly).inDays;
  }

  String accountStatusLabel(String status, String expiresAt) {
    final days = daysUntilExpiration(expiresAt);

    if (days != null && days < 0) return 'EXPIRADO';

    final normalized = status.toUpperCase();

    if (normalized == 'ACTIVE') return 'ATIVO';
    if (normalized == 'BLOCKED') return 'BLOQUEADO';
    if (normalized == 'EXPIRED') return 'EXPIRADO';

    return normalized.isEmpty ? 'ATIVO' : normalized;
  }

  Color accountStatusColor(String status, String expiresAt) {
    final label = accountStatusLabel(status, expiresAt);

    if (label == 'ATIVO') return const Color(0xFF22C55E);
    if (label == 'BLOQUEADO') return const Color(0xFFF97316);
    if (label == 'EXPIRADO') return const Color(0xFFE11D48);

    return const Color(0xFF60A5FA);
  }

  String expirationMessage(String expiresAt) {
    final days = daysUntilExpiration(expiresAt);

    if (days == null) return 'Vencimento não informado';

    if (days < 0) {
      return 'Seu plano expirou há ${days.abs()} dias.';
    }

    if (days == 0) {
      return 'Seu plano vence hoje.';
    }

    if (days == 1) {
      return 'Seu plano vence amanhã.';
    }

    return 'Seu plano vence em $days dias.';
  }

  Widget buildAccountBadge({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.45),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget buildAccountInfoTile({
    required IconData icon,
    required String title,
    required String value,
    Color? accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (accent ?? const Color(0xFF8B5CF6)).withOpacity(0.18),
              border: Border.all(
                color: (accent ?? const Color(0xFF8B5CF6)).withOpacity(0.38),
              ),
            ),
            child: Icon(
              icon,
              color: accent ?? Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Não informado' : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAccountWarning(String expiresAt) {
    final days = daysUntilExpiration(expiresAt);

    if (days == null || days > 7) return const SizedBox.shrink();

    final expired = days < 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: (expired ? const Color(0xFFE11D48) : const Color(0xFFF59E0B))
            .withOpacity(0.14),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: (expired ? const Color(0xFFE11D48) : const Color(0xFFF59E0B))
              .withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            expired
                ? Icons.warning_amber_rounded
                : Icons.notifications_active_rounded,
            color: expired ? const Color(0xFFE11D48) : const Color(0xFFF59E0B),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              expirationMessage(expiresAt),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAccountPage() {
    return FutureBuilder<List<String?>>(
      future: Future.wait([
        storage.getName(),
        storage.getUsername(),
        storage.getUserId(),
        storage.getM3uUrl(),
        storage.getExpiresAt(),
        storage.getStatus(),
        storage.getPlan(),
      ]),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const [null, null, null, null, null, null, null];

        final name = data[0] ?? 'Cliente LumaPlay';
        final username = data[1] ?? 'Usuário';
        final userId = data[2] ?? '';
        final m3uUrl = data[3] ?? '';
        final expiresAt = data[4] ?? '';
        final status = data[5] ?? 'ACTIVE';
        final plan = data[6] ?? 'Premium';

        final statusLabel = accountStatusLabel(status, expiresAt);
        final statusColor = accountStatusColor(status, expiresAt);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildPageHeader(
              'Minha Conta',
              'Dados da assinatura e informações do usuário.',
            ),
            buildAccountWarning(expiresAt),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF101833),
                    Color(0xFF050711),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF00A8FF),
                          Color(0xFF8B5CF6),
                          Color(0xFFEC4899),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '@$username',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.62),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  buildAccountBadge(
                    label: statusLabel,
                    color: statusColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width < 900 ? 1 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 4.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                buildAccountInfoTile(
                  icon: Icons.workspace_premium_rounded,
                  title: 'Plano',
                  value: plan,
                  accent: const Color(0xFF8B5CF6),
                ),
                buildAccountInfoTile(
                  icon: Icons.event_available_rounded,
                  title: 'Vencimento',
                  value: formatAccountDate(expiresAt),
                  accent: statusColor,
                ),
                buildAccountInfoTile(
                  icon: Icons.verified_user_rounded,
                  title: 'Status',
                  value: statusLabel,
                  accent: statusColor,
                ),
                buildAccountInfoTile(
                  icon: Icons.playlist_play_rounded,
                  title: 'Playlist',
                  value: m3uUrl.isEmpty ? 'Não vinculada' : 'Vinculada',
                  accent: const Color(0xFF00A8FF),
                ),
              ],
            ),
            if (userId.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'ID da conta: $userId',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.38),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final current = currentPassword.trim();
    final next = newPassword.trim();
    final confirm = confirmPassword.trim();

    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos.'),
        ),
      );
      return;
    }

    if (next.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A nova senha precisa ter pelo menos 6 caracteres.'),
        ),
      );
      return;
    }

    if (next != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A confirmação da senha não confere.'),
        ),
      );
      return;
    }

    final customerId = await storage.getUserId();

    if (customerId == null || customerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sessão inválida. Faça login novamente.'),
        ),
      );
      return;
    }

    try {
      await accountDio.post(
        '/account/$customerId/change-password',
        data: {
          'currentPassword': current,
          'newPassword': next,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Senha alterada com sucesso.'),
        ),
      );

      setState(() {
        selectedMenu = 5;
      });
    } on DioException catch (error) {
      final data = error.response?.data;
      final message = data is Map<String, dynamic>
          ? data['message']?.toString()
          : null;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message ?? 'Não foi possível alterar a senha.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro inesperado ao alterar a senha.'),
        ),
      );
    }
  }

  Widget buildPasswordPage() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildPageHeader(
          'Trocar Senha',
          'Atualize sua senha de acesso ao LumaPlay.',
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.055),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            children: [
              buildSettingsInput(
                controller: currentController,
                hint: 'Senha atual',
                icon: Icons.lock_outline_rounded,
                obscure: true,
              ),
              const SizedBox(height: 12),
              buildSettingsInput(
                controller: newController,
                hint: 'Nova senha',
                icon: Icons.password_rounded,
                obscure: true,
              ),
              const SizedBox(height: 12),
              buildSettingsInput(
                controller: confirmController,
                hint: 'Confirmar nova senha',
                icon: Icons.verified_user_rounded,
                obscure: true,
              ),
              const SizedBox(height: 16),
              _TvFocus(
                onPressed: () => changePassword(
                  currentPassword: currentController.text,
                  newPassword: newController.text,
                  confirmPassword: confirmController.text,
                ),
                childBuilder: (focused) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: focused ? 50 : 46,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF00A8FF),
                          Color(0xFF8B5CF6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: focused ? Colors.white : Colors.transparent,
                        width: focused ? 2 : 0,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.save_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Salvar nova senha',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildSettingsInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.black.withOpacity(0.28),
        prefixIcon: Icon(
          icon,
          color: Colors.white.withOpacity(0.72),
          size: 19,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.45),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF8B5CF6),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget buildTermsPage() {
    return buildLegalPage(
      title: 'Termos de Uso',
      subtitle: 'Regras de utilização do LumaPlay.',
      content: const [
        'O LumaPlay é uma plataforma de organização e reprodução de conteúdos associados à conta do usuário.',
        'O acesso é individual e protegido por usuário e senha.',
        'O usuário deve manter seus dados de acesso em segurança e não compartilhar a conta com terceiros.',
        'A disponibilidade de canais, filmes e séries pode variar conforme a origem da lista vinculada.',
        'O uso do aplicativo depende de conexão com a internet e de uma assinatura ativa.',
        'Contas vencidas, bloqueadas ou removidas podem perder o acesso ao serviço.',
      ],
    );
  }

  Widget buildPrivacyPage() {
    return buildLegalPage(
      title: 'Política de Privacidade',
      subtitle: 'Como tratamos dados usados no aplicativo.',
      content: const [
        'O LumaPlay armazena dados básicos da conta, como nome, usuário, status, vencimento e playlist vinculada.',
        'Essas informações são usadas para permitir login, personalização e controle de acesso ao aplicativo.',
        'Preferências de conteúdo, favoritos e histórico podem ser armazenados para melhorar a experiência do usuário.',
        'Não vendemos dados pessoais dos usuários.',
        'Dados técnicos podem ser usados para melhorar estabilidade, desempenho e segurança.',
        'Ao utilizar o aplicativo, o usuário concorda com o tratamento dessas informações para funcionamento do serviço.',
      ],
    );
  }

  Widget buildLegalPage({
    required String title,
    required String subtitle,
    required List<String> content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildPageHeader(title, subtitle),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.055),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: content.map((paragraph) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  paragraph,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.78),
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget buildSettingsAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
    Color accent = const Color(0xFF8B5CF6),
  }) {
    return _TvFocus(
      onPressed: onPressed,
      childBuilder: (focused) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: focused ? Colors.white : Colors.white.withOpacity(0.055),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: focused ? Colors.white : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: focused ? Colors.black : accent,
                size: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: focused ? Colors.black : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: focused
                            ? Colors.black.withOpacity(0.62)
                            : Colors.white.withOpacity(0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: focused ? Colors.black : Colors.white54,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildSettingsContent() {
    return FutureBuilder<List<String?>>(
      future: Future.wait([
        storage.getName(),
        storage.getUsername(),
        storage.getExpiresAt(),
        storage.getStatus(),
      ]),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const [null, null, null, null];

        final name = data[0] ?? 'Cliente LumaPlay';
        final username = data[1] ?? 'Usuário';
        final expiresAt = data[2] ?? '';
        final status = data[3] ?? 'ACTIVE';
        final statusLabel = accountStatusLabel(status, expiresAt);
        final statusColor = accountStatusColor(status, expiresAt);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildPageHeader(
              'Configurações',
              'Conta, preferências e segurança do LumaPlay.',
            ),
            buildAccountWarning(expiresAt),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.055),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF00A8FF),
                          Color(0xFF8B5CF6),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@$username • ${expirationMessage(expiresAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.58),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  buildAccountBadge(
                    label: statusLabel,
                    color: statusColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            buildSettingsAction(
              icon: Icons.account_circle_rounded,
              title: 'Minha Conta',
              subtitle: 'Plano, status, vencimento e dados da assinatura.',
              onPressed: () {
                setState(() {
                  detailItem = null;
                  selectedMenu = 7;
                });
              },
              accent: const Color(0xFF00A8FF),
            ),
            buildSettingsAction(
              icon: Icons.lock_reset_rounded,
              title: 'Trocar Senha',
              subtitle: 'Atualize sua senha de acesso.',
              onPressed: () {
                setState(() {
                  detailItem = null;
                  selectedMenu = 8;
                });
              },
              accent: const Color(0xFF8B5CF6),
            ),
            buildSettingsAction(
              icon: Icons.description_rounded,
              title: 'Termos de Uso',
              subtitle: 'Leia as regras de utilização.',
              onPressed: () {
                setState(() {
                  detailItem = null;
                  selectedMenu = 9;
                });
              },
              accent: const Color(0xFF38BDF8),
            ),
            buildSettingsAction(
              icon: Icons.privacy_tip_rounded,
              title: 'Política de Privacidade',
              subtitle: 'Entenda como seus dados são usados.',
              onPressed: () {
                setState(() {
                  detailItem = null;
                  selectedMenu = 10;
                });
              },
              accent: const Color(0xFF22C55E),
            ),
            buildSettingsAction(
              icon: Icons.logout_rounded,
              title: 'Sair da conta',
              subtitle: 'Encerrar sessão neste aparelho.',
              onPressed: logout,
              accent: const Color(0xFFE11D48),
            ),
          ],
        );
      },
    );
  }

  bool isGenericDescription(String value) {
    final normalized = value.toLowerCase();

    return normalized.trim().isEmpty ||
        normalized.contains('sinopse carregando') ||
        normalized.contains('importado automaticamente') ||
        normalized.contains('lista xtream') ||
        normalized.contains('lista lumaplay');
  }

  String fallbackSynopsis(_ContentItem item) {
    if (item.id.startsWith('series_')) {
      return '${item.title} está disponível na sua lista LumaPlay. Abra os episódios para assistir temporadas disponíveis.';
    }

    if (item.isLive) {
      return '${item.title} é um canal ao vivo disponível na sua lista LumaPlay.';
    }

    return '${item.title} está disponível na sua lista LumaPlay. A sinopse oficial não foi encontrada para este conteúdo.';
  }

  String detailSynopsis(_ContentItem item) {
    final cached = itemSynopses[item.id];

    if (cached != null && cached.trim().isNotEmpty) {
      return cached;
    }

    if (!isGenericDescription(item.description)) {
      return item.description;
    }

    if (loadingSynopses.contains(item.id)) {
      return 'Carregando sinopse...';
    }

    return fallbackSynopsis(item);
  }

  Future<void> loadSynopsisForItem(_ContentItem item) async {
    if (item.isLive) return;
    if (itemSynopses.containsKey(item.id)) return;
    if (loadingSynopses.contains(item.id)) return;

    setState(() {
      loadingSynopses.add(item.id);
    });

    try {
      final response = await tmdbDio.get(
        '/tmdb/overview',
        queryParameters: {
          'title': item.title,
          'year': item.year,
          'type': item.id.startsWith('series_') ? 'series' : 'movie',
        },
      );

      final data = response.data;

      final overview = data is Map<String, dynamic>
          ? data['overview']?.toString() ?? ''
          : '';

      if (!mounted) return;

      setState(() {
        if (overview.trim().isNotEmpty) {
          itemSynopses[item.id] = overview.trim();
        }

        loadingSynopses.remove(item.id);
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loadingSynopses.remove(item.id);
      });
    }
  }

  Widget buildDetailsPage(_ContentItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TvFocus(
          onPressed: () {
            setState(() {
              detailItem = null;
            });
          },
          childBuilder: (focused) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: focused ? 38 : 36,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: focused
                    ? Colors.white.withOpacity(0.16)
                    : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: focused ? Colors.white : Colors.transparent,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Voltar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Container(
          height: 310,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              fit: StackFit.expand,
              children: [
                buildHeroOrFanartImage(item),
                Container(color: Colors.black.withOpacity(0.58)),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withOpacity(0.94),
                        Colors.black.withOpacity(0.70),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: buildPosterImage(
                          item.poster,
                          width: 150,
                          height: 230,
                          fit: BoxFit.cover,
                          cacheWidth: 230,
                        ),
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _InfoPill(text: item.year),
                                const SizedBox(width: 8),
                                _InfoPill(text: item.duration),
                                const SizedBox(width: 8),
                                _InfoPill(text: item.tag),
                                const SizedBox(width: 8),
                                _InfoPill(text: item.category),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              detailSynopsis(item),
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.76),
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 22),
                            Row(
                              children: [
                                _TvFocus(
                                  onPressed: () {
                                    if (!item.isLive && item.id.startsWith('series_')) {
                                      openSeriesEpisodes(item);
                                      return;
                                    }

                                    openPlayer(item);
                                  },
                                  childBuilder: (focused) {
                                    return _ActionButton(
                                      title: item.isLive
                                          ? 'Assistir ao vivo'
                                          : item.id.startsWith('series_')
                                              ? 'Ver episódios'
                                              : 'Assistir',
                                      icon: Icons.play_arrow_rounded,
                                      primary: true,
                                      focused: focused,
                                    );
                                  },
                                ),
                                const SizedBox(width: 10),
                                _TvFocus(
                                  onPressed: () => toggleFavorite(item),
                                  childBuilder: (focused) {
                                    final favorite = isFavorite(item);

                                    return _ActionButton(
                                      title: favorite
                                          ? 'Remover favorito'
                                          : 'Favoritar',
                                      icon: favorite
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      primary: false,
                                      focused: focused,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final hours = duration.inHours;

    if (hours > 0) return '$hours:$minutes:$seconds';

    return '$minutes:$seconds';
  }

  Widget buildPlayerPage(_ContentItem item) {
    final controller = videoController;
    final initialized = controller != null && controller.value.isInitialized;
    final isVideoPlaying = initialized && controller.value.isPlaying;
    final position = initialized ? controller.value.position : Duration.zero;
    final duration = initialized ? controller.value.duration : Duration.zero;
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : position.inMilliseconds / duration.inMilliseconds;

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
        SingleActivator(LogicalKeyboardKey.goBack): DismissIntent(),
        SingleActivator(LogicalKeyboardKey.browserBack): DismissIntent(),
        SingleActivator(LogicalKeyboardKey.arrowRight): DirectionalFocusIntent(TraversalDirection.right),
        SingleActivator(LogicalKeyboardKey.arrowLeft): DirectionalFocusIntent(TraversalDirection.left),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (intent) {
              closePlayer();
              return null;
            },
          ),
        },
        child: FocusTraversalGroup(
          child: Scaffold(
            backgroundColor: Colors.black,
            body: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: showVideoControls,
              child: Stack(
                children: [
                Positioned.fill(
                  child: initialized
                      ? FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: controller.value.size.width,
                            height: controller.value.size.height,
                            child: VideoPlayer(controller),
                          ),
                        )
                      : buildPosterImage(
                          item.poster,
                          fit: BoxFit.cover,
                          cacheWidth: 850,
                        ),
                ),
                if (videoControlsVisible || videoLoading || videoError)
                  Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.28),
                          Colors.transparent,
                          Colors.black.withOpacity(0.70),
                        ],
                      ),
                    ),
                  ),
                ),
                if (videoLoading)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                if (videoError)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.58),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Text(
                        'Não foi possível carregar o vídeo.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                if (videoControlsVisible || videoLoading || videoError)
                  Center(
                  child: _TvFocus(
                    autofocus: true,
                    onPressed: togglePlay,
                    childBuilder: (focused) {
                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: focused || !isVideoPlaying ? 1 : 0.15,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: focused ? 104 : 92,
                          height: focused ? 104 : 92,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: focused
                                ? Colors.white.withOpacity(0.22)
                                : Colors.black.withOpacity(0.34),
                            border: Border.all(
                              color: focused
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.28),
                              width: focused ? 2 : 1,
                            ),
                          ),
                          child: Icon(
                            isVideoPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (videoControlsVisible || videoLoading || videoError)
                  Positioned(
                  left: 32,
                  top: 28,
                  child: _TvFocus(
                    onPressed: closePlayer,
                    childBuilder: (focused) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: focused ? 44 : 40,
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: focused
                              ? Colors.white.withOpacity(0.18)
                              : Colors.black.withOpacity(0.42),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: focused ? Colors.white : Colors.white24,
                            width: focused ? 2 : 1,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 19,
                            ),
                            SizedBox(width: 7),
                            Text(
                              'Voltar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (videoControlsVisible || videoLoading || videoError)
                  Positioned(
                  left: 36,
                  right: 36,
                  bottom: 30,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.isLive)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE11D48),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'AO VIVO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isVideoPlaying ? 'Reproduzindo' : 'Pausado',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.72),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!item.isLive)
                        Row(
                          children: [
                            _TvFocus(
                              onPressed: () => seekVideoBy(const Duration(seconds: -10)),
                              childBuilder: (focused) {
                                return _ActionButton(
                                  title: '-10s',
                                  icon: Icons.replay_10_rounded,
                                  primary: false,
                                  focused: focused,
                                );
                              },
                            ),
                            const SizedBox(width: 10),
                            _TvFocus(
                              onPressed: togglePlay,
                              childBuilder: (focused) {
                                final isPlaying = videoController?.value.isPlaying == true;

                                return _ActionButton(
                                  title: isPlaying ? 'Pausar' : 'Reproduzir',
                                  icon: isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  primary: true,
                                  focused: focused,
                                );
                              },
                            ),
                            const SizedBox(width: 10),
                            _TvFocus(
                              onPressed: () => seekVideoBy(const Duration(seconds: 10)),
                              childBuilder: (focused) {
                                return _ActionButton(
                                  title: '+10s',
                                  icon: Icons.forward_10_rounded,
                                  primary: false,
                                  focused: focused,
                                );
                              },
                            ),
                          ],
                        ),
                      if (!item.isLive)
                        const SizedBox(height: 16),
                      const SizedBox(height: 16),
                      if (!item.isLive)
                        _ScrubProgressBar(
                          position: position,
                          duration: duration,
                          onSeek: seekVideoTo,
                        )
                      else
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE11D48),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            item.isLive ? 'AO VIVO' : formatDuration(position),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.70),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            item.isLive
                                ? item.category
                                : initialized
                                    ? formatDuration(duration)
                                    : item.duration,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.70),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildOnboardingPosterCard({
    required _ContentItem item,
    required bool selected,
    required VoidCallback onPressed,
  }) {
    return _TvFocus(
      onPressed: onPressed,
      onFocus: () => selectHero(item),
      childBuilder: (focused) {
        final active = focused || selected;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? const Color(0xFF8B5CF6)
                  : active
                      ? Colors.white
                      : Colors.white.withOpacity(0.08),
              width: selected ? 3 : active ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Stack(
              fit: StackFit.expand,
              children: [
                buildPosterImage(
                  item.poster,
                  fit: BoxFit.cover,
                  cacheWidth: 210,
                ),
                if (selected)
                  Container(
                    color: Colors.black.withOpacity(0.34),
                  ),
                if (selected)
                  const Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 46,
                    ),
                  ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildOnboardingGrid({
    required List<_ContentItem> items,
    required Set<String> selectedIds,
    required ValueChanged<_ContentItem> onToggle,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        mainAxisExtent: 210,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
      ),
      itemBuilder: (context, index) {
        final item = items[index];

        return buildOnboardingPosterCard(
          item: item,
          selected: selectedIds.contains(item.id),
          onPressed: () => onToggle(item),
        );
      },
    );
  }

  Widget buildPreferencesOnboardingPage() {
    final movieOptions = moviesWithPoster.take(30).toList();
    final seriesOptions = seriesWithPoster.take(30).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildPageHeader(
            'Personalize sua LumaPlay',
            'Escolha 5 filmes e 5 séries. Vamos usar isso para montar suas recomendações.',
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Image.asset(
              'assets/images/onboarding_gostos_filmes.png',
              width: double.infinity,
              height: 260,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filmes escolhidos: ${onboardingMovieIds.length}/5',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                buildOnboardingGrid(
                  items: movieOptions,
                  selectedIds: onboardingMovieIds,
                  onToggle: toggleOnboardingMovie,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Image.asset(
              'assets/images/onboarding_gostos_series.png',
              width: double.infinity,
              height: 260,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Séries escolhidas: ${onboardingSeriesIds.length}/5',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                buildOnboardingGrid(
                  items: seriesOptions,
                  selectedIds: onboardingSeriesIds,
                  onToggle: toggleOnboardingSeries,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _TvFocus(
            onPressed: finishPreferenceOnboarding,
            childBuilder: (focused) {
              final enabled =
                  onboardingMovieIds.length >= 5 && onboardingSeriesIds.length >= 5;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: focused ? 54 : 50,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                decoration: BoxDecoration(
                  gradient: enabled
                      ? const LinearGradient(
                          colors: [
                            Color(0xFF3B82F6),
                            Color(0xFF8B5CF6),
                          ],
                        )
                      : null,
                  color: enabled ? null : Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: focused ? Colors.white : Colors.white.withOpacity(0.12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      enabled
                          ? 'Salvar e entrar'
                          : 'Escolha 5 filmes e 5 séries',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildContent() {
    if (detailItem != null) return buildDetailsPage(detailItem!);

    if (preferencesOnboardingLoaded &&
        !preferencesOnboardingCompleted &&
        !catalogLoading &&
        moviesWithPoster.length >= 5 &&
        seriesWithPoster.length >= 5) {
      return buildPreferencesOnboardingPage();
    }

    if (selectedMenu == 0) return buildHomePageContent();
    if (selectedMenu == 1) return buildMoviesPageContent();
    if (selectedMenu == 2) return buildSeriesPageContent();
    if (selectedMenu == 3) return buildLiveContent();
    if (selectedMenu == 4) return buildFavoritesPageContent();
    if (selectedMenu == 5) return buildSettingsContent();
    if (selectedMenu == 7) return buildAccountPage();
    if (selectedMenu == 8) return buildPasswordPage();
    if (selectedMenu == 9) return buildTermsPage();
    if (selectedMenu == 10) return buildPrivacyPage();

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    if (playerItem != null) return buildPlayerPage(playerItem!);

    final isCompact = false;
    final showSidebar = true;

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF030308),
        body: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.15,
                    colors: [
                      Color(0xFF1E1B4B),
                      Color(0xFF050711),
                      Color(0xFF030308),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    if (showSidebar) ...[
                    Container(
                      width: isCompact ? 205 : 215,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1020),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.04),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'LumaPlay',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              if (isCompact)
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      sidebarVisible = false;
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: ListView.builder(
                              itemCount: menus.length,
                              itemBuilder: (context, index) {
                                return buildSidebarItem(index);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    ],
                    Expanded(
                      child: SingleChildScrollView(
                        clipBehavior: Clip.hardEdge,
                        child: buildContent(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (false)
              Positioned(
                left: 14,
                top: 14,
                child: SafeArea(
                  child: _TvFocus(
                    onPressed: () {
                      setState(() {
                        sidebarVisible = true;
                      });
                    },
                    childBuilder: (focused) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: focused ? 48 : 44,
                        height: focused ? 48 : 44,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.54),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: focused ? Colors.white : Colors.white24,
                          ),
                        ),
                        child: const Icon(
                          Icons.menu_rounded,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


class _ScrubProgressBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  const _ScrubProgressBar({
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  @override
  State<_ScrubProgressBar> createState() => _ScrubProgressBarState();
}

class _ScrubProgressBarState extends State<_ScrubProgressBar> {
  bool focused = false;
  Duration? previewPosition;

  double get progress {
    if (widget.duration.inMilliseconds <= 0) return 0;

    return (widget.position.inMilliseconds / widget.duration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  String format(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (hours > 0) return '$hours:$minutes:$seconds';

    return '$minutes:$seconds';
  }

  Duration positionFromDx(double dx, double width) {
    if (widget.duration.inMilliseconds <= 0 || width <= 0) {
      return Duration.zero;
    }

    final value = (dx / width).clamp(0.0, 1.0);
    final milliseconds = (widget.duration.inMilliseconds * value).round();

    return Duration(milliseconds: milliseconds);
  }

  Future<void> seekBy(Duration offset) async {
    var next = (previewPosition ?? widget.position) + offset;

    if (next < Duration.zero) next = Duration.zero;
    if (next > widget.duration) next = widget.duration;

    setState(() {
      previewPosition = next;
    });

    widget.onSeek(next);
  }

  @override
  Widget build(BuildContext context) {
    final currentPreview = previewPosition ?? widget.position;
    final previewProgress = widget.duration.inMilliseconds <= 0
        ? 0.0
        : (currentPreview.inMilliseconds / widget.duration.inMilliseconds)
            .clamp(0.0, 1.0);

    return FocusableActionDetector(
      onFocusChange: (value) {
        setState(() {
          focused = value;
          if (!value) previewPosition = null;
        });
      },
      actions: {
        DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
          onInvoke: (intent) {
            if (intent.direction == TraversalDirection.right) {
              seekBy(const Duration(seconds: 30));
              return null;
            }

            if (intent.direction == TraversalDirection.left) {
              seekBy(const Duration(seconds: -30));
              return null;
            }

            return null;
          },
        ),
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              final next = positionFromDx(
                details.localPosition.dx,
                constraints.maxWidth,
              );

              setState(() {
                previewPosition = next;
              });

              widget.onSeek(next);
            },
            onHorizontalDragUpdate: (details) {
              final next = positionFromDx(
                details.localPosition.dx,
                constraints.maxWidth,
              );

              setState(() {
                previewPosition = next;
              });

              widget.onSeek(next);
            },
            child: SizedBox(
              height: focused ? 42 : 28,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: focused ? 9 : 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: focused ? 9 : 6,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  if (focused || previewPosition != null)
                    Positioned(
                      left: (constraints.maxWidth * previewProgress - 38)
                          .clamp(0.0, constraints.maxWidth - 76),
                      bottom: 22,
                      child: Container(
                        width: 76,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.78),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.movie_filter_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              format(currentPreview),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    left: (constraints.maxWidth * progress - 7)
                        .clamp(0.0, constraints.maxWidth - 14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: focused ? 16 : 12,
                      height: focused ? 16 : 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black.withOpacity(0.35),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LiveStyle {
  final IconData icon;
  final String poster;
  final List<Color> colors;

  const _LiveStyle({
    required this.icon,
    required this.poster,
    required this.colors,
  });
}

class _TvFocus extends StatefulWidget {
  final bool autofocus;
  final VoidCallback onPressed;
  final VoidCallback? onFocus;
  final Widget Function(bool focused) childBuilder;

  const _TvFocus({
    required this.onPressed,
    required this.childBuilder,
    this.onFocus,
    this.autofocus = false,
  });

  @override
  State<_TvFocus> createState() => _TvFocusState();
}

class _TvFocusState extends State<_TvFocus> {
  bool focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      autofocus: widget.autofocus,
      mouseCursor: SystemMouseCursors.click,
      onFocusChange: (value) {
        setState(() {
          focused = value;
        });

        if (value) widget.onFocus?.call();
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (intent) {
            widget.onPressed();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: widget.childBuilder(focused),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String text;

  const _InfoPill({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool primary;
  final bool focused;

  const _ActionButton({
    required this.title,
    required this.icon,
    required this.primary,
    required this.focused,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: focused ? 46 : 42,
      padding: const EdgeInsets.symmetric(horizontal: 17),
      decoration: BoxDecoration(
        color: primary ? Colors.white : Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: focused ? Colors.white : Colors.transparent,
          width: focused ? 2 : 0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: primary ? Colors.black : Colors.white,
            size: 19,
          ),
          const SizedBox(width: 7),
          Text(
            title,
            style: TextStyle(
              color: primary ? Colors.black : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
