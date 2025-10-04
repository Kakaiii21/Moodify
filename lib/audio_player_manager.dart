import 'package:just_audio/just_audio.dart';

class AudioPlayerManager {
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();
  factory AudioPlayerManager() => _instance;

  AudioPlayerManager._internal();

  final AudioPlayer audioPlayer = AudioPlayer();
}
