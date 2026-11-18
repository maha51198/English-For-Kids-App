import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final FlutterTts _tts = FlutterTts();
  static bool _initialized = false;
  static bool muted = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.05);
      await _tts.setVolume(1.0);
    } catch (_) {}
    _initialized = true;
  }

  static Future<void> speak(String text) async {
    if (muted) return;
    await init();
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  static void toggleMute() => muted = !muted;
}