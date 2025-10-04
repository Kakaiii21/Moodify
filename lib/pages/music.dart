import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:moodify/screens/nowPlaying.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

class Playlist extends StatefulWidget {
  const Playlist({super.key});

  @override
  State<Playlist> createState() => _PlaylistState();
}

class _PlaylistState extends State<Playlist> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _audioPlayer = AudioPlayer();

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
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 50),
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  return ListTile(
                    title: Text(song.displayNameWOExt),
                    subtitle: Text(song.artist ?? "Unknown Artist"),
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
                            songModelList: songs,
                            audioPlayer: _audioPlayer,
                            currentIndex: index, // ✅ send index
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: GestureDetector(
                  onTap: () async {
                    await _audioPlayer.stop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NowPlaying(
                          songModelList: allsongs,
                          audioPlayer: _audioPlayer,
                          currentIndex: 0,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 0, 15, 15),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(
                        context,
                      ).colorScheme.inversePrimary, // background of button
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
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor:
                          Colors.transparent, // shows container color
                      child: Icon(
                        Icons.play_arrow,
                        size: 40,
                        color: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer, // icon color
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
