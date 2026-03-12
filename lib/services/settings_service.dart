import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  // TTS
  bool get ttsEnabled => _prefs.getBool('tts_enabled') ?? true;
  set ttsEnabled(bool v) => _prefs.setBool('tts_enabled', v);

  // Haptic
  bool get hapticEnabled => _prefs.getBool('haptic_enabled') ?? true;
  set hapticEnabled(bool v) => _prefs.setBool('haptic_enabled', v);

  // Speech rate (0.0 - 1.0)
  double get speechRate => _prefs.getDouble('speech_rate') ?? 0.5;
  set speechRate(double v) => _prefs.setDouble('speech_rate', v);

  // Sign language mode
  String get signLanguage => _prefs.getString('sign_language') ?? 'ASL';
  set signLanguage(String v) => _prefs.setString('sign_language', v);

  // Space timer duration (seconds)
  int get spaceTimerSeconds => _prefs.getInt('space_timer') ?? 4;
  set spaceTimerSeconds(int v) => _prefs.setInt('space_timer', v);

  // Confidence threshold (0.0 - 1.0)
  double get confidenceThreshold => (_prefs.getDouble('confidence_threshold') ?? 0.6).clamp(0.3, 0.85);
  set confidenceThreshold(double v) => _prefs.setDouble('confidence_threshold', v);
}
