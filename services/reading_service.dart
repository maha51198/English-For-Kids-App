import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/models.dart';

enum ReadMode {
  normal,
  slow,
  spelling,
  repeat3,
}

class ReadingService {
  ReadingService._();
  static final ReadingService instance = ReadingService._();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool _muted = false;
  bool _speaking = false;

  int _generation = 0;
  Completer<void>? _currentSpeechCompleter;

  final _speakingController = StreamController<bool>.broadcast();
  Stream<bool> get onSpeakingChanged => _speakingController.stream;

  bool get isMuted => _muted;
  bool get isSpeaking => _speaking;

  // 🇬🇧 English voice ONLY
  static const String _targetLang = 'en-US';
  static const String _targetLangShort = 'en';

  Future<void> init() async {
    if (_initialized) return;
    try {
      await _tts.setLanguage(_targetLang);
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.05);
      await _tts.setVolume(1.0);

      _tts.setStartHandler(() {
        _speaking = true;
        _speakingController.add(true);
      });
      _tts.setCompletionHandler(() {
        _speaking = false;
        _speakingController.add(false);
        final c = _currentSpeechCompleter;
        if (c != null && !c.isCompleted) c.complete();
      });
      _tts.setCancelHandler(() {
        _speaking = false;
        _speakingController.add(false);
        final c = _currentSpeechCompleter;
        if (c != null && !c.isCompleted) c.complete();
      });
      _tts.setErrorHandler((msg) {
        _speaking = false;
        _speakingController.add(false);
        final c = _currentSpeechCompleter;
        if (c != null && !c.isCompleted) c.complete();
      });

      // اختيار صوت إنجليزي مناسب
      try {
        final voices = await _tts.getVoices;
        if (voices is List && voices.isNotEmpty) {
          final v = voices.firstWhere(
            (v) =>
                (v['locale'] as String?)?.toLowerCase().startsWith('en-us') ==
                true,
            orElse: () => voices.firstWhere(
              (v) =>
                  (v['locale'] as String?)
                      ?.toLowerCase()
                      .startsWith(_targetLangShort) ==
                  true,
              orElse: () => voices.first,
            ),
          );
          if (v['name'] != null) {
            await _tts.setVoice({'name': v['name'], 'locale': v['locale']});
          }
        }
      } catch (_) {}
    } catch (_) {}
    _initialized = true;
  }

  void setMuted(bool m) {
    _muted = m;
    if (m) stop();
  }

  void toggleMute() => setMuted(!_muted);

  Future<void> stop() async {
    _generation++;
    try {
      await _tts.stop();
    } catch (_) {}
    _speaking = false;
    _speakingController.add(false);
    final c = _currentSpeechCompleter;
    if (c != null && !c.isCompleted) c.complete();
    _currentSpeechCompleter = null;
  }

  /// 🔥 النطق الفوري — يُقاطع أي نطق جارٍ
  Future<void> read(WordPair pair, {ReadMode mode = ReadMode.normal}) async {
    _generation++;
    final myGen = _generation;

    try {
      await _tts.stop();
    } catch (_) {}
    _speaking = false;
    _speakingController.add(false);
    final old = _currentSpeechCompleter;
    if (old != null && !old.isCompleted) old.complete();
    _currentSpeechCompleter = null;

    await Future.delayed(const Duration(milliseconds: 20));
    if (myGen != _generation) return;

    await _readInternal(pair, mode, myGen);
  }

  Future<void> _readInternal(WordPair pair, ReadMode mode, int myGen) async {
    if (_muted) return;
    if (myGen != _generation) return;

    switch (mode) {
      case ReadMode.normal:
        await _sayNow(pair.en, rate: 0.45, gen: myGen);
        break;

      case ReadMode.slow:
        await _sayNow(pair.en, rate: 0.25, gen: myGen);
        break;

      case ReadMode.spelling:
        final letters =
            pair.en.replaceAll(RegExp(r'[^A-Za-z]'), '').split('').join(', ');
        await _sayNow(letters, rate: 0.35, gen: myGen);
        if (myGen != _generation) return;
        await Future.delayed(const Duration(milliseconds: 350));
        if (myGen != _generation) return;
        await _sayNow(pair.en, rate: 0.45, gen: myGen);
        break;

      case ReadMode.repeat3:
        for (var i = 0; i < 3; i++) {
          if (myGen != _generation) return;
          await _sayNow(pair.en, rate: 0.45, gen: myGen);
          if (myGen != _generation) return;
          await Future.delayed(const Duration(milliseconds: 450));
        }
        break;
    }
  }

  Future<void> _sayNow(
    String text, {
    double rate = 0.45,
    double pitch = 1.05,
    required int gen,
  }) async {
    if (_muted || text.trim().isEmpty) return;
    if (gen != _generation) return;

    await init();
    if (gen != _generation) return;

    final completer = Completer<void>();
    _currentSpeechCompleter = completer;

    try {
      await _tts.setLanguage(_targetLang);
      await _tts.setSpeechRate(rate);
      await _tts.setPitch(pitch);
      _speaking = true;
      _speakingController.add(true);
      await _tts.speak(text);
      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (!completer.isCompleted) completer.complete();
        },
      );
    } catch (_) {
      if (!completer.isCompleted) completer.complete();
    } finally {
      if (_currentSpeechCompleter == completer) {
        _currentSpeechCompleter = null;
      }
    }
  }

  Future<void> say(
    String text, {
    double rate = 0.45,
    double pitch = 1.05,
  }) async {
    if (_muted || text.trim().isEmpty) return;
    _generation++;
    final myGen = _generation;
    try {
      await _tts.stop();
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 20));
    if (myGen != _generation) return;
    await _sayNow(text, rate: rate, pitch: pitch, gen: myGen);
  }

  Future<void> readSequence(
    List<WordPair> pairs, {
    ReadMode mode = ReadMode.normal,
    Duration gap = const Duration(milliseconds: 900),
    void Function(int index)? onIndex,
  }) async {
    if (_muted) return;
    for (var i = 0; i < pairs.length; i++) {
      onIndex?.call(i);
      await read(pairs[i], mode: mode);
      await Future.delayed(gap);
    }
  }

  void dispose() {
    _speakingController.close();
    _tts.stop();
  }
}
