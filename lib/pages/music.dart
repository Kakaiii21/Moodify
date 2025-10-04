import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:moodify/screens/nowPlaying.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

import '../audio_player_manager.dart'; // ✅ import shared player

class Playlist extends StatefulWidget {
  const Playlist({super.key});

  @override
  State<Playlist> createState() => _PlaylistState();
}

class _PlaylistState extends State<Playlist> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _audioPlayer =
      AudioPlayerManager().audioPlayer; // shared player

  List<SongModel> allsongs = [];
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    requestPermission();
  }

  Future<void> requestPermission() async {
    PermissionStatus status;
    if (await Permission.audio.isGranted) {
      status = PermissionStatus.granted;
    } else {
      status = await Permission.audio.request();
    }

    setState(() {
      _permissionGranted = status == PermissionStatus.granted;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionGranted) {
      return const Scaffold(
        body: Center(child: Text("Permission required to access music")),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      body: FutureBuilder<List<SongModel>>(
        future: _audioQuery.querySongs(
          sortType: null,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
          ignoreCase: true,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No Songs Found"));
          }

          final songs = snapshot.data!;
          allsongs = songs;

          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  0,
                  20,
                  0,
                  100,
                ), // leave space for mini player
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];

                  bool isPlaying =
                      _audioPlayer.playing &&
                      _audioPlayer.sequenceState?.currentSource?.tag == song;

                  return ListTile(
                    title: Text(
                      song.displayNameWOExt,
                      style: TextStyle(
                        color: isPlaying
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        fontWeight: isPlaying
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      song.artist ?? "Unknown Artist",
                      style: TextStyle(
                        color: isPlaying
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade600,
                      ),
                    ),
                    trailing: const Icon(Icons.more_horiz),
                    leading: QueryArtworkWidget(
                      id: song.id,
                      type: ArtworkType.AUDIO,
                      nullArtworkWidget: const Icon(Icons.music_note),
                    ),
                    onTap: () async {
                      await _audioPlayer.stop(); // stop previous song
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NowPlaying(
                            songModelList: songs,
                            audioPlayer: _audioPlayer,
                            currentIndex: index,
                          ),
                        ),
                      ).then((_) => setState(() {}));
                    },
                  );
                },
              ),

              // Shuffle button
              Align(
                alignment: Alignment.bottomRight,
                child: GestureDetector(
                  onTap: () async {
                    await _audioPlayer.stop();

                    final shuffledSongs = List<SongModel>.from(allsongs);
                    shuffledSongs.shuffle();

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NowPlaying(
                          songModelList: shuffledSongs,
                          audioPlayer: _audioPlayer,
                          currentIndex: 0,
                          isShufflingInitially: true,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(
                      0,
                      0,
                      15,
                      80,
                    ), // move up to leave room for mini player
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.inversePrimary,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.inversePrimary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.transparent,
                      child: Icon(Icons.shuffle, size: 30),
                    ),
                  ),
                ),
              ),

              // Mini Player + Divider
              Align(
                alignment: Alignment.bottomCenter,
                child: StreamBuilder<PlayerState>(
                  stream: _audioPlayer.playerStateStream,
                  builder: (context, snapshot) {
                    final playing = _audioPlayer.playing;
                    final sequenceState = _audioPlayer.sequenceState;
                    final currentSong =
                        sequenceState?.currentSource?.tag as SongModel?;

                    if (currentSong == null) return const SizedBox();

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Mini Player Container
                        // Mini Player Container
                        GestureDetector(
                          onTap: () {
                            final currentIndex = allsongs.indexWhere(
                              (song) => song.id == currentSong.id,
                            );
                            if (currentIndex == -1) return; // safety check

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NowPlaying(
                                  songModelList: allsongs,
                                  audioPlayer:
                                      _audioPlayer, // shared player, continues from current position
                                  currentIndex: currentIndex,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            height: 70,
                            color: Theme.of(context).colorScheme.primary,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Artwork + Song info
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: QueryArtworkWidget(
                                        id: currentSong.id,
                                        type: ArtworkType.AUDIO,
                                        artworkHeight: 50,
                                        artworkWidth: 50,
                                        artworkFit: BoxFit.cover,
                                        nullArtworkWidget: Container(
                                          height: 50,
                                          width: 50,
                                          color: Colors.grey.shade400,
                                          child: const Icon(
                                            Icons.music_note,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          currentSong.displayNameWOExt,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.inversePrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          currentSong.artist ??
                                              "Unknown Artist",
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.inversePrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // Play/Pause Button
                                IconButton(
                                  onPressed: () {
                                    if (playing) {
                                      _audioPlayer.pause();
                                    } else {
                                      _audioPlayer.play();
                                    }
                                  },
                                  icon: Icon(
                                    playing
                                        ? Icons.pause_circle_filled
                                        : Icons.play_circle_filled,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.inversePrimary,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Divider below mini player
                        Container(
                          height: .3,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
