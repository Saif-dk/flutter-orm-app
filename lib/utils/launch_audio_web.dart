import 'dart:html' as html;

html.AudioElement? _audioElement;

Future<void> playLaunchAudio() async {
  try {
    // Create an AudioElement that points to the asset path.
    // Browsers require a user gesture to start playback; the Start button satisfies that.
    _audioElement = html.AudioElement('assets/sounds/helicopter.mp3')
      ..autoplay = true
      ..loop = false;
    await _audioElement!.play();
  } catch (_) {
    // ignore errors (playback may be blocked or file missing)
  }
}

Future<void> disposeLaunchAudio() async {
  try {
    _audioElement?.pause();
    _audioElement?.src = '';
    _audioElement = null;
  } catch (_) {}
}
