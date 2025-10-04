import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../theme/theme_provider.dart';

class NowPlaying extends StatefulWidget {
  const NowPlaying({
    super.key,
    required this.songModelList,
    required this.audioPlayer,
    required this.currentIndex,
    this.isShufflingInitially = false, // default false
  });

  final List<SongModel> songModelList;
  final AudioPlayer audioPlayer;
  final int currentIndex;
  final bool isShufflingInitially; // <- this is correct here

  @override
  State<NowPlaying> createState() => _NowPlayingState();
}

class _NowPlayingState extends State<NowPlaying> {
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isShuffling = false;
  bool _isLooping = false;
  late int _currentIndex;
  late SongModel _currentSong;

  // Notifiers to prevent unnecessary rebuilds
  late ValueNotifier<SongModel> currentSongNotifier;
  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _currentSong = widget.songModelList[_currentIndex];
    currentSongNotifier = ValueNotifier(_currentSong);
    _isShuffling = widget.isShufflingInitially;

    playSong();
    listenToStreams();
  }

  void listenToStreams() {
    widget.audioPlayer.durationStream.listen((d) {
      if (d != null) setState(() => _duration = d);
    });

    widget.audioPlayer.positionStream.listen((p) {
      positionNotifier.value = p; // ✅ update position without setState
    });

    widget.audioPlayer.playerStateStream.listen((state) {
      setState(() => _isPlaying = state.playing);
    });

    widget.audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed && !_isLooping) {
        skipNext();
      }
    });
  }

  Future<void> playSong() async {
    try {
      final song = widget.songModelList[_currentIndex];
      _currentSong = song;

      // Only set a new audio source if it's a different song
      final currentTag = widget.audioPlayer.sequenceState?.currentSource?.tag;
      if (currentTag?.id != song.id) {
        await widget.audioPlayer.stop();
        await widget.audioPlayer.setAudioSource(
          AudioSource.uri(Uri.parse(song.uri!), tag: song),
        );
      }

      currentSongNotifier.value = song; // Notify immediately
      if (!widget.audioPlayer.playing) {
        await widget.audioPlayer.play();
      }
    } on Exception catch (e) {
      log("Cannot play song: $e");
    }
  }

  void changeToSeconds(int seconds) {
    final newDuration = Duration(seconds: seconds);
    widget.audioPlayer.seek(newDuration);
  }

  void skipNext() {
    setState(() {
      if (_isShuffling) {
        _currentIndex =
            (widget.songModelList.length *
                    (DateTime.now().millisecondsSinceEpoch % 1000) /
                    1000)
                .floor() %
            widget.songModelList.length;
      } else if (_currentIndex < widget.songModelList.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      playSong();
    });
  }

  void skipPrevious() {
    setState(() {
      if (_currentIndex > 0) {
        _currentIndex--;
      } else {
        _currentIndex = widget.songModelList.length - 1;
      }
      playSong();
    });
  }

  void toggleShuffle() {
    setState(() => _isShuffling = !_isShuffling);
  }

  void toggleLoop() {
    setState(() {
      _isLooping = !_isLooping;
      widget.audioPlayer.setLoopMode(_isLooping ? LoopMode.one : LoopMode.off);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.themeData;
    final activeColor = theme.colorScheme.inversePrimary; // active buttons
    final inactiveColor = theme.colorScheme.inversePrimary;
    final color = Theme.of(context).colorScheme.inversePrimary;

    return Scaffold(
      resizeToAvoidBottomInset:
          true, // ✅ allows screen to resize when keyboard appears

      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 40),

              // ✅ Flicker-free artwork
              Center(
                child: ValueListenableBuilder<SongModel>(
                  valueListenable: currentSongNotifier,
                  builder: (context, song, _) => SongArtwork(song: song),
                ),
              ),

              const SizedBox(height: 40),

              // ✅ Slider and Duration with ValueNotifier
              ValueListenableBuilder<Duration>(
                valueListenable: positionNotifier,
                builder: (context, position, _) => Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbColor: Theme.of(
                          context,
                        ).colorScheme.inversePrimary,
                        activeTrackColor: Theme.of(
                          context,
                        ).colorScheme.inversePrimary,
                        inactiveTrackColor: Theme.of(
                          context,
                        ).colorScheme.inversePrimary.withOpacity(0.3),
                      ),
                      child: Slider(
                        min: 0,
                        max: _duration.inSeconds.toDouble(),
                        value: position.inSeconds
                            .clamp(0, _duration.inSeconds)
                            .toDouble(),
                        onChanged: (value) => changeToSeconds(value.toInt()),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(position)),
                        Text(_formatDuration(_duration)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Loop / Play / Shuffle Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Shuffle button with circular background when active
                  GestureDetector(
                    onTap: toggleShuffle,
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: _isShuffling
                          ? Theme.of(context).colorScheme.inversePrimary
                          : Colors.transparent, // no background when inactive
                      child: Icon(
                        Icons.shuffle,
                        color: _isShuffling
                            ? Theme.of(context).colorScheme.secondaryContainer
                            : inactiveColor,
                        size: 30,
                      ),
                    ),
                  ),

                  IconButton(
                    icon: Icon(
                      Icons.skip_previous_rounded,
                      size: 45,
                      color: inactiveColor,
                    ),
                    onPressed: skipPrevious,
                  ),
                  GestureDetector(
                    onTap: () {
                      if (_isPlaying) {
                        widget.audioPlayer.pause();
                      } else {
                        widget.audioPlayer.play();
                      }
                    },
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.inversePrimary,
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: theme
                            .colorScheme
                            .secondaryContainer, // ensures contrast
                        size: 40,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.skip_next_rounded,
                      size: 45,
                      color: inactiveColor,
                    ),
                    onPressed: skipNext,
                  ),
                  IconButton(
                    icon: Icon(
                      _isLooping ? Icons.repeat_one : Icons.repeat,
                      color: _isLooping ? activeColor : inactiveColor,
                    ),
                    iconSize: 35,
                    onPressed: toggleLoop,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}

class SongArtwork extends StatefulWidget {
  final SongModel song;
  const SongArtwork({super.key, required this.song});

  @override
  State<SongArtwork> createState() => _SongArtworkState();
}

class _SongArtworkState extends State<SongArtwork> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.inversePrimary.withOpacity(0.3),
                blurRadius: 80,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: QueryArtworkWidget(
              key: ValueKey(widget.song.id),
              id: widget.song.id,
              type: ArtworkType.AUDIO,
              artworkHeight: 300,
              artworkWidth: 300,
              artworkFit: BoxFit.cover,

              // ✅ Higher-quality artwork settings:
              quality: 100, // 0–100 (default is 50)
              size: 800, // request larger image resolution (default is 200)

              nullArtworkWidget: Container(
                height: 300,
                width: 300,
                color: Theme.of(context).colorScheme.surface,
                child: Icon(
                  Icons.music_note,
                  size: 100,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Text(
          widget.song.displayNameWOExt,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        const SizedBox(height: 8),
        Text(
          widget.song.artist ?? "Unknown Artist",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
      ],
    );
  }
}
