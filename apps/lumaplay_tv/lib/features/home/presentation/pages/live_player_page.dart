import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class LivePlayerItem {
  final String title;
  final String category;
  final String streamUrl;
  final String poster;
  final String logoUrl;
  final bool isLive;

  const LivePlayerItem({
    required this.title,
    required this.category,
    required this.streamUrl,
    required this.poster,
    this.logoUrl = '',
    this.isLive = true,
  });
}

class LivePlayerPage extends StatefulWidget {
  final List<LivePlayerItem> items;
  final int initialIndex;

  const LivePlayerPage({
    super.key,
    required this.items,
    required this.initialIndex,
  });

  @override
  State<LivePlayerPage> createState() => _LivePlayerPageState();
}

class _LivePlayerPageState extends State<LivePlayerPage> {
  VideoPlayerController? controller;
  Timer? hideControlsTimer;

  late int currentIndex;

  bool loading = true;
  bool error = false;
  bool controlsVisible = true;

  LivePlayerItem get currentItem => widget.items[currentIndex];

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    loadChannel();
  }

  @override
  void dispose() {
    hideControlsTimer?.cancel();
    controller?.dispose();
    super.dispose();
  }

  void showControls() {
    hideControlsTimer?.cancel();

    if (mounted) {
      setState(() {
        controlsVisible = true;
      });
    }

    hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || loading || error) return;

      setState(() {
        controlsVisible = false;
      });
    });
  }

  void keepControlsVisible() {
    hideControlsTimer?.cancel();

    if (!mounted) return;

    setState(() {
      controlsVisible = true;
    });
  }

  Future<void> loadChannel() async {
    await controller?.dispose();

    final newController = VideoPlayerController.networkUrl(
      Uri.parse(currentItem.streamUrl),
    );

    setState(() {
      controller = newController;
      loading = true;
      error = false;
      controlsVisible = true;
    });

    try {
      await newController.initialize();
      await newController.setLooping(currentItem.isLive);
      await newController.play();

      if (!mounted) return;

      setState(() {
        loading = false;
        error = false;
      });

      showControls();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = true;
      });
    }
  }

  Future<void> togglePlay() async {
    showControls();

    final video = controller;

    if (video == null || !video.value.isInitialized) return;

    if (video.value.isPlaying) {
      await video.pause();
    } else {
      await video.play();
    }

    if (!mounted) return;
    setState(() {});
  }

  void nextChannel() {
    showControls();

    if (widget.items.length <= 1) return;

    setState(() {
      currentIndex = currentIndex + 1;

      if (currentIndex >= widget.items.length) {
        currentIndex = 0;
      }
    });

    loadChannel();
  }

  void previousChannel() {
    showControls();

    if (widget.items.length <= 1) return;

    setState(() {
      currentIndex = currentIndex - 1;

      if (currentIndex < 0) {
        currentIndex = widget.items.length - 1;
      }
    });

    loadChannel();
  }

  void closePlayer() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final video = controller;
    final initialized = video != null && video.value.isInitialized;
    final playing = initialized && video.value.isPlaying;

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
        SingleActivator(LogicalKeyboardKey.goBack): DismissIntent(),
        SingleActivator(LogicalKeyboardKey.arrowRight): NextFocusIntent(),
        SingleActivator(LogicalKeyboardKey.arrowLeft): PreviousFocusIntent(),
      },
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              showControls();
              return null;
            },
          ),
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              closePlayer();
              return null;
            },
          ),
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: showControls,
            child: Stack(
              children: [
              Positioned.fill(
                child: initialized
                    ? FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: video.value.size.width,
                          height: video.value.size.height,
                          child: VideoPlayer(video),
                        ),
                      )
                    : Image.asset(
                        currentItem.poster,
                        fit: BoxFit.cover,
                      ),
              ),

              if (controlsVisible || loading || error)
                Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.50),
                        Colors.transparent,
                        Colors.black.withOpacity(0.88),
                      ],
                    ),
                  ),
                ),
              ),

              if (loading)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.62),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 18),
                        Text(
                          'Carregando canal...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (error)
                Center(
                  child: Container(
                    width: 430,
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.72),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.white,
                          size: 54,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Não foi possível abrir este canal',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentItem.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Canal ${currentIndex + 1} de ${widget.items.length} • ${currentItem.category}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.50),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _PlayerButton(
                              autofocus: true,
                              icon: Icons.refresh_rounded,
                              title: 'Tentar novamente',
                              onPressed: loadChannel,
                            ),
                            const SizedBox(width: 12),
                            _PlayerButton(
                              icon: Icons.skip_next_rounded,
                              title: 'Próximo',
                              onPressed: nextChannel,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              if (controlsVisible || loading || error)
                Positioned(
                left: 32,
                top: 28,
                child: _PlayerButton(
                  icon: Icons.arrow_back_rounded,
                  title: 'Voltar',
                  onPressed: closePlayer,
                ),
              ),

              if (controlsVisible || loading || error)
                Center(
                child: _RoundPlayerButton(
                  autofocus: true,
                  icon: playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  onPressed: togglePlay,
                ),
              ),

              if (controlsVisible || loading || error)
                Positioned(
                left: 40,
                right: 40,
                bottom: 34,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const _LiveBadge(),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.48),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            'Canal ${currentIndex + 1} de ${widget.items.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      currentItem.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Categoria: ${currentItem.category}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.70),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE11D48),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _PlayerButton(
                          icon: Icons.skip_previous_rounded,
                          title: 'Canal anterior',
                          onPressed: previousChannel,
                        ),
                        const SizedBox(width: 12),
                        _PlayerButton(
                          icon: playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          title: playing ? 'Pausar' : 'Reproduzir',
                          onPressed: togglePlay,
                        ),
                        const SizedBox(width: 12),
                        _PlayerButton(
                          icon: Icons.skip_next_rounded,
                          title: 'Próximo canal',
                          onPressed: nextChannel,
                        ),
                        const Spacer(),
                        Text(
                          '${currentIndex + 1}/${widget.items.length}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.70),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
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
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
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
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _RoundPlayerButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool autofocus;

  const _RoundPlayerButton({
    required this.icon,
    required this.onPressed,
    this.autofocus = false,
  });

  @override
  State<_RoundPlayerButton> createState() => _RoundPlayerButtonState();
}

class _RoundPlayerButtonState extends State<_RoundPlayerButton> {
  bool focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      autofocus: widget.autofocus,
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
          duration: const Duration(milliseconds: 160),
          width: focused ? 110 : 94,
          height: focused ? 110 : 94,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: focused
                ? Colors.white.withOpacity(0.24)
                : Colors.black.withOpacity(0.38),
            border: Border.all(
              color: focused ? Colors.white : Colors.white30,
              width: focused ? 2 : 1,
            ),
          ),
          child: Icon(
            widget.icon,
            color: Colors.white,
            size: 62,
          ),
        ),
      ),
    );
  }
}

class _PlayerButton extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onPressed;
  final bool autofocus;

  const _PlayerButton({
    required this.icon,
    required this.title,
    required this.onPressed,
    this.autofocus = false,
  });

  @override
  State<_PlayerButton> createState() => _PlayerButtonState();
}

class _PlayerButtonState extends State<_PlayerButton> {
  bool focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      autofocus: widget.autofocus,
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
          height: focused ? 46 : 42,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: focused
                ? Colors.white.withOpacity(0.22)
                : Colors.black.withOpacity(0.46),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: focused ? Colors.white : Colors.white24,
              width: focused ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: Colors.white,
                size: 19,
              ),
              const SizedBox(width: 7),
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

