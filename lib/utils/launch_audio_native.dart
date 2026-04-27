import 'dart:async';
import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('orm_risk_assessment/launch_audio');

Future<void> playLaunchAudio() async {
  try {
    await _channel.invokeMethod('play');
  } catch (_) {}
}

Future<void> disposeLaunchAudio() async {
  try {
    await _channel.invokeMethod('dispose');
  } catch (_) {}
}
