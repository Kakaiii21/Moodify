import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:moodify/screens/nowPlaying.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

import '../audio_player_manager.dart';

class Playlist extends StatefulWidget {
  const Playlist({super.key});

  @override
  State<Playlist> createState() => _PlaylistState();
}

class _PlaylistState extends State<Playlist> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _audioPlayer = AudioPlayerManager().audioPlayer;

  List<SongModel> allsongs = [];
  List<SongModel> filteredSongs = [];
  bool _permissionGranted = false;
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    requestPermission();
  }

  Future<void> requestPermission() async {
    var status = await Permission.audio.request();
    if (status.isGranted) {
      setState(() => _permissionGranted = true);
      await _loadSongs();
    } else {
      setState(() => _permissionGranted = false);
    }
  }

  Future<void> _loadSongs() async {
    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.DISPLAY_NAME,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    setState(() {
      allsongs = songs;
      filteredSongs = songs;
      _isLoading = false;
    });
  }

  void _filterSongs(String query) {
    final results = query.isEmpty
        ? allsongs
        : allsongs.where((song) {
            final title = song.displayNameWOExt.toLowerCase();
            final artist = song.artist?.toLowerCase() ?? '';
            return title.contains(query.toLowerCase()) ||
                artist.contains(query.toLowerCase());
          }).toList();

    setState(() => filteredSongs = results);
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionGranted) {
      return const Scaffold(
        body: Center(child: Text("Permission required to access music")),
      );
    }

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool miniPlayerActive =
        _audioPlayer.sequenceState?.currentSource?.tag != null;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 🔍 Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 15, 15, 10),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterSongs,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search songs or artists...',
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.inversePrimary.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                    ),
                  ),
                ),

                // 🎵 Song List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 100),
                    itemCount: filteredSongs.length,
                    itemBuilder: (context, index) {
                      final song = filteredSongs[index];
                      final isPlaying =
                          _audioPlayer.playing &&
                          _audioPlayer.sequenceState?.currentSource?.tag ==
                              song;

                      return ListTile(
                        title: Text(
                          song.displayNameWOExt,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
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
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
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
                          await _audioPlayer.stop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NowPlaying(
                                songModelList: filteredSongs,
                                audioPlayer: _audioPlayer,
                                currentIndex: index,
                              ),
                            ),
                          ).then((_) => setState(() {}));
                        },
                      );
                    },
                  ),
                ),
              ],
            ),

            // 🔀 Shuffle Button
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
                  margin: EdgeInsets.fromLTRB(
                    0,
                    0,
                    15,
                    miniPlayerActive ? 100 : 20,
                  ),
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

                                  // Make title and artist text flexible
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.45, // adjust width to fit UI
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          currentSong.displayNameWOExt,
                                          maxLines: 1,
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
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.inversePrimary,
                                          ),
                                        ),
                                      ],
                                    ),
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
        ),
      ),
    );
  }
}
