import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

class NowPlaying extends StatefulWidget {
  const NowPlaying({
    super.key,
    required this.songModel,
    required this.audioPlayer,
  });

  final SongModel songModel;
  final AudioPlayer audioPlayer;

  @override
  State<NowPlaying> createState() => _NowPlayingState();
}

class _NowPlayingState extends State<NowPlaying> {
  Duration _duration = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    playSong();
  }

  Future<void> playSong() async {
    try {
      await widget.audioPlayer.setAudioSource(
        AudioSource.uri(Uri.parse(widget.songModel.uri!)),
      );
      widget.audioPlayer.play();
      _isPlaying = true;
    } on Exception {
      log("Cannot Parse Song");
    }

    widget.audioPlayer.durationStream.listen((d) {
      if (d != null) {
        setState(() {
          _duration = d;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Cache the artwork so it doesn’t rebuild on every position change
    final artwork = QueryArtworkWidget(
      id: widget.songModel.id,
      type: ArtworkType.AUDIO,
      artworkHeight: 200,
      artworkWidth: 200,
      artworkFit: BoxFit.cover,
      nullArtworkWidget: const Icon(Icons.music_note, size: 200),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios),
              ),
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    artwork, // ✅ this stays stable
                    const SizedBox(height: 40),
                    Text(
                      widget.songModel.displayNameWOExt,
                      overflow: TextOverflow.fade,
                      maxLines: 1,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 30.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.songModel.artist ?? "Unknown Artist",
                      overflow: TextOverflow.fade,
                      maxLines: 1,
                      style: const TextStyle(fontSize: 20.0),
                    ),
                    const SizedBox(height: 40),

                    // ✅ Only the slider & time update via StreamBuilder
                    StreamBuilder<Duration>(
                      stream: widget.audioPlayer.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        return Row(
                          children: [
                            Text(position.toString().split(".")[0]),
                            Expanded(
                              child: SliderTheme(
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
                                  min: 0.0,
                                  value: position.inSeconds
                                      .clamp(0, _duration.inSeconds)
                                      .toDouble(),
                                  max: _duration.inSeconds.toDouble(),
                                  onChanged: (value) {
                                    widget.audioPlayer.seek(
                                      Duration(seconds: value.toInt()),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Text(_duration.toString().split(".")[0]),
                          ],
                        );
                      },
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.skip_previous),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (_isPlaying) {
                                widget.audioPlayer.pause();
                              } else {
                                widget.audioPlayer.play();
                              }
                              _isPlaying = !_isPlaying;
                            });
                          },
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.orangeAccent,
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.skip_next),
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
    );
  }
}
