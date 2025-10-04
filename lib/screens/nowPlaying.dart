import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

class NowPlaying extends StatefulWidget {
  const NowPlaying({super.key, required this.songModel});
  final SongModel songModel;

  @override
  State<NowPlaying> createState() => _NowPlayingState();
}

class _NowPlayingState extends State<NowPlaying> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isPlaying = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    playSong();
  }

  void playSong() {
    try {
      _audioPlayer.setAudioSource(
        AudioSource.uri(Uri.parse(widget.songModel.uri!)),
      );
      _audioPlayer.play();
      _isPlaying = true;
    } on Exception {
      log("Cannot Parse Song");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.arrow_back_ios),
              ),
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 100,
                      child: Icon(Icons.music_note, size: 80),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      widget.songModel.displayNameWOExt,
                      overflow: TextOverflow.fade,
                      maxLines: 1,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 30.0,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      widget.songModel.artistId.toString() == "<unknown>"
                          ? "Unknown Artist"
                          : widget.songModel.artistId.toString(),
                      overflow: TextOverflow.fade,
                      maxLines: 1,
                      style: TextStyle(fontSize: 20.0),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text("0.0"),
                        Expanded(
                          child: Slider(value: 0.0, onChanged: (value) {}),
                        ),
                        Text("0.0"),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.skip_previous),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (_isPlaying) {
                                _audioPlayer.pause();
                              } else {
                                _audioPlayer.play();
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
                          icon: Icon(Icons.skip_next),
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
