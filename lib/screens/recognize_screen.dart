import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/app_colors.dart';
import '../services/asl_model_service.dart';
import '../services/settings_service.dart';
import '../services/history_service.dart';
import '../services/tts_service.dart';

class RecognizeScreen extends StatefulWidget {
  const RecognizeScreen({super.key});
  @override
  State<RecognizeScreen> createState() => _RecognizeScreenState();
}

class _RecognizeScreenState extends State<RecognizeScreen>
    with TickerProviderStateMixin {

  // ── CAMERA ────────────────────────────────────────────────
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _cameraPermission = false;
  bool _isDetecting = false; // detection ON/OFF button
  bool _cameraReady = false;
  int _cameraIndex = 0;

  // ── MODEL ─────────────────────────────────────────────────
  final ASLModelService _model = ASLModelService();
  final _settings = SettingsService();
  final _historyService = HistoryService();
  final _tts = TtsService();
  String _detectedSign = '—';
  double _confidence = 0.0;
  bool _modelLoaded = false;

  // ── TRANSCRIPT ────────────────────────────────────────────
  String _transcript = '';
  String _lastSign = '';
  int _sameSignCount = 0;
  Timer? _inferenceTimer;
  Timer? _spaceTimer;          // auto-space after 2s no detection
  DateTime? _lastDetectionTime;

  // ── MODE ──────────────────────────────────────────────────
  String _mode = 'ASL';
  final List<String> _modes = ['ASL', 'BSL', 'ISL'];

  // ── DEMO ──────────────────────────────────────────────────
  final List<String> _demoSigns = ['H', 'E', 'L', 'L', 'O', 'W', 'O', 'R', 'L', 'D'];
  int _demoIndex = 0;

  // ── ANIMATIONS ────────────────────────────────────────────
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _signController;
  late Animation<double> _signScale;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _settings.init();
    _loadModel();
    _requestCameraPermission();
  }

  void _setupAnimations() {
    _scanController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(_scanController);

    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _signController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _signScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _signController, curve: Curves.elasticOut));
  }

  Future<void> _loadModel() async {
    // Wait for Flutter engine to fully initialize
    await Future.delayed(const Duration(seconds: 1));
    await _model.loadModel();
    if (mounted) setState(() => _modelLoaded = _model.isLoaded);
    print('Model loaded: $_modelLoaded');
    
    // Retry once more if failed
    if (!_modelLoaded) {
      await Future.delayed(const Duration(seconds: 2));
      await _model.loadModel();
      if (mounted) setState(() => _modelLoaded = _model.isLoaded);
      print('Model loaded after retry: $_modelLoaded');
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() => _cameraPermission = true);
      await _initCamera();
    }
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;
    // prefer front camera
    _cameraIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front);
    if (_cameraIndex < 0) _cameraIndex = 0;
    await _startCamera();
  }

  Future<void> _startCamera() async {
    if (_cameras.isEmpty) return;
    final controller = CameraController(
      _cameras[_cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    _cameraController = controller;
    await controller.initialize();
    // Disable flash — prevents auto torch during detection
    await controller.setFlashMode(FlashMode.off);
    if (mounted) setState(() => _cameraReady = true);
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    await _cameraController?.dispose();
    _cameraController = null;
    setState(() => _cameraReady = false);
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _startCamera();
  }

  // ── TOGGLE DETECTION (Start / Stop button) ────────────────
  void _toggleDetection() {
    setState(() => _isDetecting = !_isDetecting);
    if (_isDetecting) {
      _inferenceTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
        if (_isDetecting) _runInference();
      });
    } else {
      _inferenceTimer?.cancel();
    _spaceTimer?.cancel();
      _inferenceTimer = null;
      _spaceTimer?.cancel();
      // Save transcript to history when stopping
      if (_transcript.trim().isNotEmpty) {
        _historyService.init().then((_) => _historyService.saveEntry(_transcript));
      }
      // Reset everything when stopped — no more ghost detections
      setState(() {
        _detectedSign = '—';
        _confidence = 0.0;
        _lastSign = '';
        _sameSignCount = 0;
      });
    }
  }

  // ── INFERENCE (only runs when _isDetecting == true) ───────
  Future<void> _runInference() async {
    if (!_isDetecting) return;
    if (_cameraController == null || !_cameraReady) return;

    try {
      // Capture real frame if model is loaded
      if (_model.isLoaded) {
        final xFile = await _cameraController!.takePicture();
        final scores = await _model.runInferenceOnFile(xFile.path);
        final top = _model.getTopPrediction(scores);
        final sign = top.key;
        final conf = top.value;

        // Only count high confidence detections
        if (conf < _settings.confidenceThreshold) return;

        // Reset space timer on every detection
        _lastDetectionTime = DateTime.now();
        _spaceTimer?.cancel();
        _spaceTimer = Timer(Duration(seconds: _settings.spaceTimerSeconds), () {
          // No sign detected for 2 seconds — add space
          if (_transcript.isNotEmpty && !_transcript.endsWith(' ') && _isDetecting) {
            _addToTranscript('space');
          }
        });

        if (sign != _lastSign) {
          _lastSign = sign;
          _sameSignCount = 1;
          _signController.forward(from: 0);
          if (mounted) setState(() { _detectedSign = sign; _confidence = conf; });
        } else {
          _sameSignCount++;
          if (_sameSignCount == 3) {
            _addToTranscript(sign);
            _sameSignCount = 0;
          }
        }
      } else {
        // Demo mode fallback
        _demoIndex = (_demoIndex + 1) % _demoSigns.length;
        final sign = _demoSigns[_demoIndex];
        final conf = 0.87 + (DateTime.now().millisecond % 13) * 0.01;
        if (sign != _lastSign) {
          _lastSign = sign;
          _sameSignCount = 1;
          _signController.forward(from: 0);
          if (mounted) setState(() { _detectedSign = sign; _confidence = conf; });
        } else {
          _sameSignCount++;
          if (_sameSignCount == 3) { _addToTranscript(sign); _sameSignCount = 0; }
        }
      }
    } catch (e) {
      print('Inference error: $e');
    }
  }

  void _addToTranscript(String sign) {
    if (sign == 'del') {
      if (_transcript.isNotEmpty)
        setState(() => _transcript = _transcript.substring(0, _transcript.length - 1));
    } else if (sign == 'space') {
      setState(() => _transcript += ' ');
    } else if (sign != 'nothing') {
      setState(() => _transcript += sign);
      if (_settings.hapticEnabled) HapticFeedback.lightImpact();
      if (_settings.ttsEnabled) _tts.speak(sign);
    }
  }

  void _clearTranscript() {
    setState(() { _transcript = ''; _lastSign = ''; _sameSignCount = 0; });
  }

  @override
  void dispose() {
    _inferenceTimer?.cancel();
    _spaceTimer?.cancel();
    _cameraController?.dispose();
    _model.dispose();
    _scanController.dispose();
    _pulseController.dispose();
    _signController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Camera takes 52% of screen height — large and visible
    final cameraH = size.height * 0.52;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: [
                _buildCameraSection(cameraH),
                _buildDetectionPanel(),
                _buildTranscriptPanel(),
                _buildStartStopButton(),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ── TOP BAR ───────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accent2]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(child: Text('🤟', style: TextStyle(fontSize: 18))),
        ),
        const SizedBox(width: 10),
        RichText(text: const TextSpan(
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          children: [
            TextSpan(text: 'Sign', style: TextStyle(color: AppColors.textColor)),
            TextSpan(text: 'Bridge', style: TextStyle(color: AppColors.accent)),
          ],
        )),
        const Spacer(),
        // Mode selector
        ..._modes.map((m) => GestureDetector(
          onTap: () => setState(() => _mode = m),
          child: Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _mode == m ? AppColors.accent.withOpacity(0.15) : Colors.transparent,
              border: Border.all(
                color: _mode == m ? AppColors.accent.withOpacity(0.5) : AppColors.border),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(m, style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: _mode == m ? AppColors.accent : AppColors.muted,
            )),
          ),
        )),
      ]),
    );
  }

  // ── CAMERA SECTION ────────────────────────────────────────
  Widget _buildCameraSection(double cameraH) {
    return Container(
      margin: const EdgeInsets.all(12),
      height: cameraH,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _isDetecting
              ? AppColors.accent.withOpacity(0.7)
              : AppColors.border,
          width: _isDetecting ? 2.5 : 1.5,
        ),
        boxShadow: _isDetecting
            ? [BoxShadow(color: AppColors.accent.withOpacity(0.2), blurRadius: 24, spreadRadius: 2)]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        // ── Camera preview fills 100% of box ──────────────
        if (_cameraReady && _cameraController != null)
          Positioned.fill(
            child: CameraPreview(_cameraController!),
          )
        else
          _buildCameraPlaceholder(cameraH),

        // ── Scan line (only when detecting) ───────────────
        if (_isDetecting)
          AnimatedBuilder(
            animation: _scanAnimation,
            builder: (_, __) => Positioned(
              top: _scanAnimation.value * cameraH - 2,
              left: 0, right: 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.transparent,
                    AppColors.accent.withOpacity(0.9),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ),

        // ── Corner brackets (only when detecting) ─────────
        if (_isDetecting)
          Positioned.fill(child: CustomPaint(painter: _CornerPainter())),

        // ── Status chips top-left ──────────────────────────
        Positioned(
          top: 12, left: 12,
          child: Row(children: [
            _Chip(
              label: _isDetecting ? '● LIVE' : '○ PAUSED',
              color: _isDetecting ? const Color(0xFFEF4444) : AppColors.muted,
            ),
            const SizedBox(width: 6),
            GestureDetector(onTap: _loadModel, child: _Chip(label: _model.isLoaded ? 'AI Mode' : 'Demo Mode', color: _model.isLoaded ? AppColors.accent3 : AppColors.muted)),
            const SizedBox(width: 6),
            _Chip(label: '30fps', color: AppColors.muted),
          ]),
        ),

        // ── Flip camera button bottom-right ───────────────
        Positioned(
          bottom: 14, right: 14,
          child: GestureDetector(
            onTap: _flipCamera,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.flip_camera_android_rounded,
                  color: AppColors.textColor, size: 22),
            ),
          ),
        ),

        // ── Detected letter overlay (bottom-left) ─────────
        if (_isDetecting && _detectedSign != '—')
          Positioned(
            bottom: 14, left: 14,
            child: AnimatedBuilder(
              animation: _signController,
              builder: (_, child) =>
                  Transform.scale(scale: _signScale.value, child: child),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accent.withOpacity(0.6)),
                ),
                child: Text(_detectedSign,
                    style: const TextStyle(
                      fontSize: 42, fontWeight: FontWeight.w900,
                      color: AppColors.accent,
                      shadows: [Shadow(color: Color(0x8800E5FF), blurRadius: 16)],
                    )),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _buildCameraPlaceholder(double h) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, child) =>
                Transform.scale(scale: _pulseAnimation.value, child: child),
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(0.1),
                border: Border.all(color: AppColors.accent.withOpacity(0.4), width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  color: AppColors.accent, size: 36),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _cameraPermission ? 'Initializing camera...' : 'Camera permission required',
            style: const TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          if (!_cameraPermission) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _requestCameraPermission,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFF06B6D4)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Grant Permission',
                    style: TextStyle(color: AppColors.bg, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  // ── DETECTION PANEL ───────────────────────────────────────
  Widget _buildDetectionPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        // Detected sign
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('DETECTED SIGN',
              style: TextStyle(fontSize: 10, letterSpacing: 1.2,
                  color: AppColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: _signController,
            builder: (_, child) => Transform.scale(
              scale: _signScale.value, alignment: Alignment.centerLeft, child: child),
            child: Text(
              // Only show sign when detection is ON
              _isDetecting ? _detectedSign : '—',
              style: const TextStyle(
                fontSize: 58, fontWeight: FontWeight.w900,
                color: AppColors.accent, height: 1,
                shadows: [Shadow(color: Color(0x5500E5FF), blurRadius: 16)],
              ),
            ),
          ),
        ]),
        const SizedBox(width: 16),
        // Confidence + mode
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('CONFIDENCE',
                style: TextStyle(fontSize: 10, letterSpacing: 1,
                    color: AppColors.muted, fontWeight: FontWeight.w600)),
            Text(
              _isDetecting ? '${(_confidence * 100).toStringAsFixed(0)}%' : '—',
              style: const TextStyle(fontSize: 12, color: AppColors.textColor,
                  fontWeight: FontWeight.w600),
            ),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _isDetecting ? _confidence : 0),
              duration: const Duration(milliseconds: 500),
              builder: (_, val, __) => LinearProgressIndicator(
                value: val,
                backgroundColor: AppColors.bg,
                valueColor: AlwaysStoppedAnimation<Color>(
                  val > 0.8 ? AppColors.accent3 : AppColors.accent),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text('MODE',
              style: TextStyle(fontSize: 10, letterSpacing: 1,
                  color: AppColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: Text('$_mode Mode',
                style: const TextStyle(fontSize: 12, color: AppColors.accent,
                    fontWeight: FontWeight.w700)),
          ),
        ])),
      ]),
    );
  }

  // ── TRANSCRIPT PANEL ──────────────────────────────────────
  Widget _buildTranscriptPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('TRANSCRIPTION',
              style: TextStyle(fontSize: 10, letterSpacing: 1.2,
                  color: AppColors.muted, fontWeight: FontWeight.w600)),
          const Spacer(),
          // Clear button
          GestureDetector(
            onTap: _clearTranscript,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.close_rounded,
                  color: AppColors.muted, size: 16),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 55),
          child: Text(
            _transcript.isEmpty ? 'Start detection to build transcript...' : _transcript,
            style: TextStyle(
              fontSize: 18,
              color: _transcript.isEmpty ? AppColors.muted : AppColors.textColor,
              fontWeight: _transcript.isEmpty ? FontWeight.w300 : FontWeight.w600,
              fontStyle: _transcript.isEmpty ? FontStyle.italic : FontStyle.normal,
              letterSpacing: _transcript.isEmpty ? 0 : 2,
              height: 1.4,
            ),
          ),
        ),
      ]),
    );
  }

  // ── START / STOP BUTTON ───────────────────────────────────
  Widget _buildStartStopButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GestureDetector(
        onTap: _toggleDetection,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: _isDetecting
                ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)])
                : const LinearGradient(colors: [AppColors.accent, Color(0xFF06B6D4)]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _isDetecting
                    ? const Color(0xFFEF4444).withOpacity(0.3)
                    : AppColors.accent.withOpacity(0.3),
                blurRadius: 20, offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(
              _isDetecting ? Icons.stop_rounded : Icons.play_arrow_rounded,
              color: AppColors.bg, size: 26,
            ),
            const SizedBox(width: 10),
            Text(
              _isDetecting ? 'Stop Detection' : 'Start Detection',
              style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800,
                color: AppColors.bg,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── CORNER BRACKET PAINTER ────────────────────────────────────
class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const len = 28.0;
    final corners = [
      [Offset(0, 0), Offset(len, 0), Offset(0, len)],
      [Offset(size.width, 0), Offset(size.width - len, 0), Offset(size.width, len)],
      [Offset(0, size.height), Offset(len, size.height), Offset(0, size.height - len)],
      [Offset(size.width, size.height), Offset(size.width - len, size.height), Offset(size.width, size.height - len)],
    ];
    for (final c in corners) {
      canvas.drawLine(c[0], c[1], paint);
      canvas.drawLine(c[0], c[2], paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// ── STATUS CHIP ───────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
