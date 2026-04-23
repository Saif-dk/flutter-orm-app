// Conditional facade: exports the web implementation when building for web,
// otherwise exports a no-op stub. This lets callers import this file and
// use the top-level functions `playLaunchAudio()` and `disposeLaunchAudio()`.
export 'launch_audio_stub.dart' if (dart.library.html) 'launch_audio_web.dart';
