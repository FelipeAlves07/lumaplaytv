import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../data/xtream_series_repository.dart';
import '../../domain/xtream_episode.dart';

class SeriesDetailsPage extends StatefulWidget {
  final String seriesId;
  final String title;
  final String poster;

  const SeriesDetailsPage({
    super.key,
    required this.seriesId,
    required this.title,
    required this.poster,
  });

  @override
  State<SeriesDetailsPage> createState() => _SeriesDetailsPageState();
}

class _SeriesDetailsPageState extends State<SeriesDetailsPage> {
  final repository = XtreamSeriesRepository();

  bool loading = true;
  bool error = false;

  XtreamSeriesInfo? info;
  String selectedSeason = '';

  VideoPlayerController? controller;
  XtreamEpisode? playingEpisode;

  bool videoLoading = false;
  bool videoError = false;
  bool controlsVisible = true;
  Timer? controlsTimer;

  @override
  void initState() {
    super.initState();
    loadInfo();
  }

  @override
  void dispose() {
    controlsTimer?.cancel();
    controller?.dispose();
    super.dispose();
  }

  Future<void> loadInfo() async {
    setState(() {
      loading = true;
      error = false;
    });

    final result = await repository.getSeriesInfo(widget.seriesId);

    if (!mounted) return;

    if (result == null || result.seasons.isEmpty) {
      setState(() {
        loading = false;
        error = true;
      });
      return;
    }

    final seasons = result.seasons.keys.toList()
      ..sort((a, b) {
        final ai = int.tryParse(a) ?? 0;
        final bi = int.tryParse(b) ?? 0;
        return ai.compareTo(bi);
      });

    setState(() {
      info = result;
      selectedSeason = seasons.first;
      loading = false;
      error = false;
    });
  }

  List<XtreamEpisode> get currentEpisodes {
    final currentInfo = info;

    if (currentInfo == null || selectedSeason.isEmpty) {
      return [];
    }

    return currentInfo.seasons[selectedSeason] ?? [];
  }

  Future<void> playEpisode(XtreamEpisode episode) async {
    await controller?.dispose();

    final nextController = VideoPlayerController.networkUrl(
      Uri.parse(episode.streamUrl),
    );

    nextController.addListener(() {
      if (!mounted || playingEpisode == null) return;
      setState(() {});
    });

    setState(() {
      controller = nextController;
      playingEpisode = episode;
      videoLoading = true;
      videoError = false;
      controlsVisible = true;
    });

    try {
      await nextController.initialize();
      await nextController.play();

      if (!mounted) return;

      setState(() {
        videoLoading = false;
        videoError = false;
      });

      showControlsTemporarily();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        videoLoading = false;
        videoError = true;
      });
    }
  }

  void closePlayer() async {
    final oldController = controller;

    setState(() {
      controller = null;
      playingEpisode = null;
      videoLoading = false;
      videoError = false;
      controlsVisible = true;
    });

    await oldController?.dispose();
  }

  Future<void> togglePlay() async {
    final video = controller;

    if (video == null || !video.value.isInitialized) return;

    if (video.value.isPlaying) {
      await video.pause();
    } else {
      await video.play();
    }

    if (!mounted) return;

    setState(() {});
    showControlsTemporarily();
  }

  Future<void> seekEpisodeBy(Duration offset) async {
    final video = controller;

    showControlsTemporarily();

    if (video == null || !video.value.isInitialized) return;

    final current = video.value.position;
    final duration = video.value.duration;
    var next = current + offset;

    if (next < Duration.zero) {
      next = Duration.zero;
    }

    if (duration > Duration.zero && next > duration) {
      next = duration;
    }

    await video.seekTo(next);

    if (!mounted) return;

    setState(() {});
  }

  Future<void> seekEpisodeTo(Duration position) async {
    final video = controller;

    showControlsTemporarily();

    if (video == null || !video.value.isInitialized) return;

    final duration = video.value.duration;
    var next = position;

    if (next < Duration.zero) {
      next = Duration.zero;
    }

    if (duration > Duration.zero && next > duration) {
      next = duration;
    }

    await video.seekTo(next);

    if (!mounted) return;

    setState(() {});
  }

  void showControlsTemporarily() {
    controlsTimer?.cancel();

    if (mounted) {
      setState(() {
        controlsVisible = true;
      });
    }

    controlsTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || videoLoading || videoError) return;

      setState(() {
        controlsVisible = false;
      });
    });
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final hours = duration.inHours;

    if (hours > 0) return '$hours:$minutes:$seconds';

    return '$minutes:$seconds';
  }

  Widget buildPoster(String poster) {
    final hasPoster =
        poster.startsWith('http://') || poster.startsWith('https://');

    if (!hasPoster) {
      return buildNoPoster();
    }

    return Image.network(
      poster,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
      errorBuilder: (_, _, _) => buildNoPoster(),
    );
  }

  Widget buildNoPoster() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF182033),
            Color(0xFF080B12),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tv_rounded,
              color: Colors.white54,
              size: 46,
            ),
            SizedBox(height: 10),
            Text(
              'SEM CAPA',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPlayer() {
    final video = controller;
    final episode = playingEpisode;

    if (video == null || episode == null) return const SizedBox.shrink();

    final initialized = video.value.isInitialized;
    final playing = initialized && video.value.isPlaying;
    final position = initialized ? video.value.position : Duration.zero;
    final duration = initialized ? video.value.duration : Duration.zero;
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
            onInvoke: (_) {
              closePlayer();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: showControlsTemporarily,
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                Positioned.fill(
                  child: initialized
                      ? FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: video.value.size.width,
                            height: video.value.size.height,
                            child: VideoPlayer(video),
                          ),
                        )
                      : buildPoster(
                          episode.poster.isEmpty ? widget.poster : episode.poster,
                        ),
                ),
                if (videoLoading)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                if (videoError)
                  const Center(
                    child: Text(
                      'Não foi possível abrir este episódio.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                AnimatedOpacity(
                  opacity: controlsVisible || !playing ? 1 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: IgnorePointer(
                    ignoring: !(controlsVisible || !playing),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.48),
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.82),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 28,
                          top: 24,
                          child: _SeriesButton(
                            icon: Icons.arrow_back_rounded,
                            title: 'Voltar',
                            onPressed: closePlayer,
                          ),
                        ),
                        Center(
                          child: _RoundButton(
                            icon: playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            onPressed: togglePlay,
                          ),
                        ),
                        Positioned(
                          left: 34,
                          right: 34,
                          bottom: 28,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                episode.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Temporada ${episode.season} • Episódio ${episode.episodeNumber}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.72),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Row(
                                children: [
                                  _SeriesButton(
                                    icon: Icons.replay_10_rounded,
                                    title: '-10s',
                                    onPressed: () => seekEpisodeBy(
                                      const Duration(seconds: -10),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _SeriesButton(
                                    icon: playing
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    title: playing ? 'Pausar' : 'Reproduzir',
                                    onPressed: togglePlay,
                                  ),
                                  const SizedBox(width: 10),
                                  _SeriesButton(
                                    icon: Icons.forward_10_rounded,
                                    title: '+10s',
                                    onPressed: () => seekEpisodeBy(
                                      const Duration(seconds: 10),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const SizedBox(height: 14),
                              _EpisodeScrubProgressBar(
                                position: position,
                                duration: duration,
                                onSeek: seekEpisodeTo,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    formatDuration(position),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.70),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    initialized
                                        ? formatDuration(duration)
                                        : episode.duration,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildContent() {
    final currentInfo = info;
    final episodes = currentEpisodes;
    final seasons = currentInfo?.seasons.keys.toList() ?? [];

    seasons.sort((a, b) {
      final ai = int.tryParse(a) ?? 0;
      final bi = int.tryParse(b) ?? 0;
      return ai.compareTo(bi);
    });

    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (error || currentInfo == null) {
      return Center(
        child: Container(
          width: 460,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 14),
              const Text(
                'Não foi possível carregar os episódios.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              _SeriesButton(
                icon: Icons.refresh_rounded,
                title: 'Tentar novamente',
                onPressed: loadInfo,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SeriesButton(
            icon: Icons.arrow_back_rounded,
            title: 'Voltar',
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 18),
          Container(
            height: 230,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  buildPoster(
                    currentInfo.cover.isEmpty ? widget.poster : currentInfo.cover,
                  ),
                  Container(color: Colors.black.withOpacity(0.62)),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox(
                            width: 130,
                            height: 190,
                            child: buildPoster(
                              currentInfo.cover.isEmpty
                                  ? widget.poster
                                  : currentInfo.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentInfo.title.isEmpty
                                    ? widget.title
                                    : currentInfo.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${seasons.length} temporadas • ${episodes.length} episódios nesta temporada',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.72),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                currentInfo.plot.isEmpty
                                    ? 'Série importada da sua lista IPTV.'
                                    : currentInfo.plot,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.72),
                                  fontSize: 13,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
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
          const SizedBox(height: 18),
          const Text(
            'Temporadas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: seasons.length,
              itemBuilder: (context, index) {
                final season = seasons[index];
                final selected = selectedSeason == season;

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _ChipButton(
                    title: 'T$season',
                    selected: selected,
                    onPressed: () {
                      setState(() {
                        selectedSeason = season;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Episódios da temporada $selectedSeason',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: episodes.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 430,
              mainAxisExtent: 92,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final episode = episodes[index];

              return _EpisodeCard(
                episode: episode,
                onPressed: () => playEpisode(episode),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (playingEpisode != null) {
      return buildPlayer();
    }

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF030308),
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topRight,
              radius: 1.12,
              colors: [
                Color(0xFF1E1B4B),
                Color(0xFF050711),
                Color(0xFF030308),
              ],
            ),
          ),
          child: SafeArea(
            child: buildContent(),
          ),
        ),
      ),
    );
  }
}


class _EpisodeScrubProgressBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  const _EpisodeScrubProgressBar({
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  @override
  State<_EpisodeScrubProgressBar> createState() => _EpisodeScrubProgressBarState();
}

class _EpisodeScrubProgressBarState extends State<_EpisodeScrubProgressBar> {
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

class _EpisodeCard extends StatefulWidget {
  final XtreamEpisode episode;
  final VoidCallback onPressed;

  const _EpisodeCard({
    required this.episode,
    required this.onPressed,
  });

  @override
  State<_EpisodeCard> createState() => _EpisodeCardState();
}

class _EpisodeCardState extends State<_EpisodeCard> {
  bool focused = false;

  @override
  Widget build(BuildContext context) {
    final number = widget.episode.episodeNumber.isEmpty
        ? ''
        : 'E${widget.episode.episodeNumber} • ';

    return FocusableActionDetector(
      onFocusChange: (value) {
        setState(() {
          focused = value;
        });
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: focused ? Colors.white : Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: focused ? Colors.white : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.play_circle_outline_rounded,
                color: focused ? Colors.black : Colors.white,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$number${widget.episode.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: focused ? Colors.black : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.episode.duration.isEmpty
                          ? 'Assistir episódio'
                          : widget.episode.duration,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: focused
                            ? Colors.black.withOpacity(0.62)
                            : Colors.white.withOpacity(0.58),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
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
}

class _ChipButton extends StatefulWidget {
  final String title;
  final bool selected;
  final VoidCallback onPressed;

  const _ChipButton({
    required this.title,
    required this.selected,
    required this.onPressed,
  });

  @override
  State<_ChipButton> createState() => _ChipButtonState();
}

class _ChipButtonState extends State<_ChipButton> {
  bool focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onFocusChange: (value) {
        setState(() {
          focused = value;
        });
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: widget.selected
                ? const LinearGradient(
                    colors: [
                      Color(0xFF3B82F6),
                      Color(0xFF8B5CF6),
                    ],
                  )
                : null,
            color: widget.selected
                ? null
                : focused
                    ? Colors.white.withOpacity(0.16)
                    : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: focused ? Colors.white : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Center(
            child: Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _RoundButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return _SeriesButton(
      icon: icon,
      title: '',
      onPressed: onPressed,
      round: true,
    );
  }
}

class _SeriesButton extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onPressed;
  final bool round;

  const _SeriesButton({
    required this.icon,
    required this.title,
    required this.onPressed,
    this.round = false,
  });

  @override
  State<_SeriesButton> createState() => _SeriesButtonState();
}

class _SeriesButtonState extends State<_SeriesButton> {
  bool focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onFocusChange: (value) {
        setState(() {
          focused = value;
        });
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.round ? (focused ? 106 : 94) : null,
          height: widget.round ? (focused ? 106 : 94) : (focused ? 46 : 42),
          padding: widget.round
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            shape: widget.round ? BoxShape.circle : BoxShape.rectangle,
            color: focused ? Colors.white : Colors.black.withOpacity(0.46),
            borderRadius: widget.round ? null : BorderRadius.circular(999),
            border: Border.all(
              color: focused ? Colors.white : Colors.white24,
              width: focused ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: focused ? Colors.black : Colors.white,
                size: widget.round ? 58 : 19,
              ),
              if (widget.title.isNotEmpty) ...[
                const SizedBox(width: 7),
                Text(
                  widget.title,
                  style: TextStyle(
                    color: focused ? Colors.black : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
