import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  Future<void> init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _tts.setStartHandler(() => _isSpeaking = true);
    _tts.setCompletionHandler(() => _isSpeaking = false);
  }

  Future<void> speak(String text) async {
    if (_isSpeaking) await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  Future<void> setSpeechRate(double rate) async {
    await _tts.setSpeechRate(rate);
  }

  bool get isSpeaking => _isSpeaking;

  void dispose() {
    _tts.stop();
  }
}
