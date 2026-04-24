import 'package:audioplayers/audioplayers.dart';

final AudioPlayer _player = AudioPlayer();

Future<void> playLaunchAudio() async {
  try {
    await _player.play(AssetSource('sounds/helicopter.mp3'));
  } catch (_) {}
}

Future<void> disposeLaunchAudio() async {
  try {
    await _player.stop();
    await _player.dispose();
  } catch (_) {}
}
