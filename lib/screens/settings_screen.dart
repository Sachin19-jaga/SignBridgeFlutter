import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_colors.dart';
import '../services/settings_service.dart';
import '../services/tts_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = SettingsService();
  final _tts = TtsService();
  bool _loaded = false;

  // Local state (synced to SettingsService)
  late bool _ttsEnabled;
  late bool _hapticEnabled;
  late double _speechRate;
  late String _signLanguage;
  late int _spaceTimer;
  late double _confidenceThreshold;

  final List<String> _languages = ['ASL', 'BSL', 'ISL'];
  final List<int> _spaceTimerOptions = [2, 3, 4, 5, 6];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _settings.init();
    setState(() {
      _ttsEnabled = _settings.ttsEnabled;
      _hapticEnabled = _settings.hapticEnabled;
      _speechRate = _settings.speechRate;
      _signLanguage = _settings.signLanguage;
      _spaceTimer = _settings.spaceTimerSeconds;
      _confidenceThreshold = _settings.confidenceThreshold.clamp(0.3, 0.85);
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildModelInfo()),
            SliverToBoxAdapter(child: _buildRecognitionSettings()),
            SliverToBoxAdapter(child: _buildAudioSettings()),
            SliverToBoxAdapter(child: _buildAbout()),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.settings_rounded, color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textColor)),
              Text('All settings are saved automatically', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  // ── AI MODEL INFO ──────────────────────────────────────────
  Widget _buildModelInfo() {
    return _Section(
      title: '🧠 AI Model',
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.accent.withOpacity(0.1), AppColors.accent2.withOpacity(0.05)]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.accent.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              _InfoRow(icon: Icons.memory_rounded, label: 'Model', value: 'ASL CNN TFLite', valueColor: AppColors.accent),
              const SizedBox(height: 10),
              _InfoRow(icon: Icons.folder_rounded, label: 'File', value: 'asl_model.tflite', valueColor: AppColors.textColor),
              const SizedBox(height: 10),
              _InfoRow(icon: Icons.check_circle_rounded, label: 'Classes', value: 'A–Z (26 letters)', valueColor: AppColors.accent3),
              const SizedBox(height: 10),
              _InfoRow(icon: Icons.analytics_rounded, label: 'Dataset', value: '87,000 hand images', valueColor: AppColors.textColor),
              const SizedBox(height: 10),
              _InfoRow(icon: Icons.speed_rounded, label: 'Inference', value: 'On-device (offline)', valueColor: AppColors.textColor),
            ],
          ),
        ),
      ],
    );
  }

  // ── RECOGNITION SETTINGS ───────────────────────────────────
  Widget _buildRecognitionSettings() {
    return _Section(
      title: '🤟 Recognition',
      children: [
        // Sign Language
        _SettingRow(
          icon: Icons.language_rounded,
          label: 'Sign Language',
          subtitle: 'Currently only ASL model is trained',
          trailing: DropdownButton<String>(
            value: _signLanguage,
            dropdownColor: AppColors.surface2,
            underline: const SizedBox(),
            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 14),
            items: _languages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
            onChanged: (v) {
              setState(() => _signLanguage = v!);
              _settings.signLanguage = v!;
              HapticFeedback.selectionClick();
            },
          ),
        ),
        const Divider(color: AppColors.border, height: 1),

        // Space timer
        _SettingRow(
          icon: Icons.timer_rounded,
          label: 'Auto-Space Timer',
          subtitle: 'Seconds of no sign before adding space',
          trailing: DropdownButton<int>(
            value: _spaceTimer,
            dropdownColor: AppColors.surface2,
            underline: const SizedBox(),
            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 14),
            items: _spaceTimerOptions.map((s) => DropdownMenuItem(value: s, child: Text('${s}s'))).toList(),
            onChanged: (v) {
              setState(() => _spaceTimer = v!);
              _settings.spaceTimerSeconds = v!;
              HapticFeedback.selectionClick();
            },
          ),
        ),
        const Divider(color: AppColors.border, height: 1),

        // Haptic feedback
        _ToggleRow(
          icon: Icons.vibration_rounded,
          label: 'Haptic Feedback',
          subtitle: 'Vibrate when a sign is detected',
          value: _hapticEnabled,
          onChanged: (v) {
            setState(() => _hapticEnabled = v);
            _settings.hapticEnabled = v;
            if (v) HapticFeedback.mediumImpact();
          },
        ),
      ],
    );
  }

  // ── AUDIO / TTS SETTINGS ───────────────────────────────────
  Widget _buildAudioSettings() {
    return _Section(
      title: '🔊 Audio',
      children: [
        // TTS toggle
        _ToggleRow(
          icon: Icons.record_voice_over_rounded,
          label: 'Text-to-Speech',
          subtitle: 'Speak detected signs out loud',
          value: _ttsEnabled,
          onChanged: (v) async {
            setState(() => _ttsEnabled = v);
            _settings.ttsEnabled = v;
            if (v) await _tts.speak('Text to speech enabled');
          },
        ),
        const Divider(color: AppColors.border, height: 1),

        // Speech rate slider
        _SliderRow(
          icon: Icons.speed_rounded,
          label: 'Speech Rate',
          subtitle: 'How fast the voice speaks',
          value: _speechRate,
          min: 0.1,
          max: 1.0,
          divisions: 9,
          displayValue: _speechRate < 0.35 ? 'Slow' : _speechRate < 0.65 ? 'Normal' : 'Fast',
          onChanged: (v) async {
            setState(() => _speechRate = v);
            _settings.speechRate = v;
            await _tts.setSpeechRate(v);
          },
        ),
        const Divider(color: AppColors.border, height: 1),

        // Test TTS button
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: GestureDetector(
            onTap: () async {
              if (_ttsEnabled) {
                await _tts.speak('Sign Bridge is ready');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enable Text-to-Speech first'), backgroundColor: AppColors.surface2),
                );
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_rounded, color: AppColors.accent, size: 18),
                  SizedBox(width: 8),
                  Text('Test Voice', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── ABOUT ──────────────────────────────────────────────────
  Widget _buildAbout() {
    return _Section(
      title: 'ℹ️ About',
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accent2]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Text('🤟', style: TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SignBridge', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textColor)),
                      Text('Version 1.0.0', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text('AI-powered ASL sign language recognition app.\nTrained on 87,000 real hand images.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _Tag('TFLite'),
                  const SizedBox(width: 8),
                  _Tag('CNN Model'),
                  const SizedBox(width: 8),
                  _Tag('On-device AI'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── HELPERS ────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textColor)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;
  const _ToggleRow({required this.label, required this.subtitle, required this.value, required this.onChanged, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.muted, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: AppColors.textColor, fontWeight: FontWeight.w600, fontSize: 14)),
            Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          ])),
          Switch(value: value, onChanged: onChanged, activeColor: AppColors.accent, activeTrackColor: AppColors.accent.withOpacity(0.3), inactiveTrackColor: AppColors.border, inactiveThumbColor: AppColors.muted),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label, subtitle;
  final Widget trailing;
  final IconData icon;
  const _SettingRow({required this.label, required this.subtitle, required this.trailing, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.muted, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: AppColors.textColor, fontWeight: FontWeight.w600, fontSize: 14)),
            Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          ])),
          trailing,
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label, subtitle, displayValue;
  final double value, min, max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final IconData icon;
  const _SliderRow({required this.label, required this.subtitle, required this.value, required this.min, required this.max, required this.divisions, required this.displayValue, required this.onChanged, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(children: [
            Icon(icon, color: AppColors.muted, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(color: AppColors.textColor, fontWeight: FontWeight.w600, fontSize: 14)),
              Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            ])),
            Text(displayValue, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.accent,
              overlayColor: AppColors.accent.withOpacity(0.15),
            ),
            child: Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color valueColor;
  const _InfoRow({required this.icon, required this.label, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: AppColors.muted, size: 16),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      const Spacer(),
      Text(value, style: TextStyle(color: valueColor, fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Text(text, style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}
