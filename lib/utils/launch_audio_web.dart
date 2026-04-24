import 'dart:html' as html;

html.AudioElement? _audioElement;

Future<void> playLaunchAudio() async {
  try {
    _audioElement = html.AudioElement('assets/sounds/helicopter.mp3')
      ..autoplay = true
      ..loop = false;
    await _audioElement!.play();
  } catch (_) {}
}

Future<void> disposeLaunchAudio() async {
  try {
    _audioElement?.pause();
    _audioElement?.src = '';
    _audioElement = null;
  } catch (_) {}
}
