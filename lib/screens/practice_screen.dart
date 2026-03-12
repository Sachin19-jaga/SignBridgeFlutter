import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/app_colors.dart';
import '../services/asl_model_service.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});
  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen>
    with TickerProviderStateMixin {

  CameraController? _cam;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _camReady = false;
  bool _camPermission = false;

  final _model = ASLModelService();
  bool _modelLoaded = false;

  final List<String> _letters = List.generate(26, (i) => String.fromCharCode(65 + i));
  String _targetLetter = 'A';
  String _detectedLetter = '—';
  double _confidence = 0.0;
  bool _isCorrect = false;
  bool _isPracticing = false;
  int _score = 0;
  int _attempts = 0;
  int _streak = 0;
  int _bestStreak = 0;
  Timer? _detectionTimer;
  Timer? _successTimer;
  bool _showSuccess = false;

  late AnimationController _successController;
  late Animation<double> _successScale;
  late AnimationController _pulseController;
  late Animation<double> _pulse;

  final Map<String, String> _signEmoji = {
    'A':'✊','B':'🖐️','C':'🤏','D':'👆','E':'🤜','F':'👌',
    'G':'👉','H':'🤞','I':'🤙','J':'🤙','K':'✌️','L':'🤙',
    'M':'✊','N':'✊','O':'👌','P':'👇','Q':'👇','R':'🤞',
    'S':'✊','T':'✊','U':'✌️','V':'✌️','W':'🤟','X':'☝️',
    'Y':'🤙','Z':'☝️',
  };

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _successScale = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _successController, curve: Curves.elasticOut));
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulse = Tween(begin: 0.97, end: 1.03).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _pickRandomLetter();
    // Delay camera init to avoid conflict with other screens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), _initCamera);
    });
    _loadModel();
  }

  Future<void> _loadModel() async {
    await Future.delayed(const Duration(seconds: 1));
    await _model.loadModel();
    if (mounted) setState(() => _modelLoaded = _model.isLoaded);
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) setState(() => _camPermission = false);
      return;
    }
    if (mounted) setState(() => _camPermission = true);

    try {
      // Dispose old controller first
      await _cam?.dispose();
      if (mounted) setState(() { _cam = null; _camReady = false; });

      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      // Clamp index
      _cameraIndex = _cameraIndex.clamp(0, _cameras.length - 1);

      final controller = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);

      if (mounted) {
        setState(() {
          _cam = controller;
          _camReady = true;
        });
      }
    } catch (e) {
      print('Camera error: $e');
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _initCamera();
  }

  void _pickRandomLetter() {
    final random = Random();
    String newLetter;
    do {
      newLetter = _letters[random.nextInt(_letters.length)];
    } while (newLetter == _targetLetter && _letters.length > 1);
    setState(() {
      _targetLetter = newLetter;
      _detectedLetter = '—';
      _confidence = 0.0;
      _isCorrect = false;
      _showSuccess = false;
    });
  }

  void _startPractice() {
    setState(() => _isPracticing = true);
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) => _runDetection());
  }

  void _stopPractice() {
    _detectionTimer?.cancel();
    _successTimer?.cancel();
    setState(() {
      _isPracticing = false;
      _detectedLetter = '—';
      _confidence = 0.0;
      _isCorrect = false;
      _showSuccess = false;
    });
  }

  Future<void> _runDetection() async {
    if (!_isPracticing || _cam == null || !_camReady || _showSuccess) return;
    try {
      final xFile = await _cam!.takePicture();
      final scores = await _model.runInferenceOnFile(xFile.path);
      final top = _model.getTopPrediction(scores);
      if (mounted) {
        setState(() {
          _detectedLetter = top.key;
          _confidence = top.value;
        });
        if (top.key == _targetLetter && top.value > 0.6) _onCorrect();
      }
    } catch (e) { /* ignore */ }
  }

  void _onCorrect() {
    if (_showSuccess) return;
    HapticFeedback.heavyImpact();
    _successController.forward(from: 0);
    setState(() {
      _isCorrect = true;
      _showSuccess = true;
      _score++;
      _attempts++;
      _streak++;
      if (_streak > _bestStreak) _bestStreak = _streak;
    });
    _successTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) { _pickRandomLetter(); _successController.reset(); }
    });
  }

  void _skipLetter() {
    setState(() { _attempts++; _streak = 0; });
    HapticFeedback.mediumImpact();
    _pickRandomLetter();
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _successTimer?.cancel();
    _cam?.dispose();
    _model.dispose();
    _successController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStatsBar(),
            Expanded(child: _buildCameraSection()),
            _buildTargetCard(),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.accent2.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.fitness_center_rounded, color: AppColors.accent2, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Practice Mode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textColor)),
              Text('Sign the letter shown below', style: TextStyle(color: AppColors.muted, fontSize: 11)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _modelLoaded ? AppColors.accent3.withOpacity(0.1) : AppColors.muted.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _modelLoaded ? AppColors.accent3.withOpacity(0.4) : AppColors.muted.withOpacity(0.3)),
            ),
            child: Text(_modelLoaded ? 'AI Mode' : 'Demo', style: TextStyle(color: _modelLoaded ? AppColors.accent3 : AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat('Score', '$_score', AppColors.accent3),
          _divider(),
          _Stat('Attempts', '$_attempts', AppColors.accent),
          _divider(),
          _Stat('Streak', '🔥 $_streak', Colors.orange),
          _divider(),
          _Stat('Best', '$_bestStreak', AppColors.accent2),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 24, color: AppColors.border);

  // Big camera section — takes most of screen
  Widget _buildCameraSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Camera preview
            if (_camReady && _cam != null)
              CameraPreview(_cam!)
            else
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _camPermission ? Icons.camera_alt_rounded : Icons.no_photography_rounded,
                        color: AppColors.muted, size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _camPermission ? 'Starting camera...' : 'Camera permission required',
                        style: const TextStyle(color: AppColors.muted, fontSize: 14),
                      ),
                      if (!_camPermission) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _initCamera,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                            ),
                            child: const Text('Grant Permission', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // Active detection border
            if (_isPracticing && !_showSuccess)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accent, width: 3),
                ),
              ),

            // Success overlay
            if (_showSuccess)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.accent3.withOpacity(0.4),
                  border: Border.all(color: AppColors.accent3, width: 3),
                ),
                child: Center(
                  child: ScaleTransition(
                    scale: _successScale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('✅', style: TextStyle(fontSize: 72)),
                        const SizedBox(height: 8),
                        Text('Correct! +1', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black54, blurRadius: 8)])),
                      ],
                    ),
                  ),
                ),
              ),

            // Detected letter badge (bottom left)
            if (_isPracticing && !_showSuccess)
              Positioned(
                bottom: 12, left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _detectedLetter == _targetLetter ? AppColors.accent3 : AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Text('Detected: ', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                      Text(_detectedLetter, style: TextStyle(
                        color: _detectedLetter == _targetLetter ? AppColors.accent3 : AppColors.textColor,
                        fontSize: 18, fontWeight: FontWeight.w900,
                      )),
                      if (_confidence > 0) ...[
                        const SizedBox(width: 6),
                        Text('${(_confidence * 100).round()}%', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                      ],
                    ],
                  ),
                ),
              ),

            // Flip camera button
            Positioned(
              top: 12, left: 12,
              child: GestureDetector(
                onTap: _flipCamera,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.flip_camera_android_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),

            // LIVE badge
            if (_isPracticing)
              Positioned(
                top: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(children: [
                    Icon(Icons.circle, color: Colors.white, size: 8),
                    SizedBox(width: 4),
                    Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Target letter card
  Widget _buildTargetCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _isCorrect ? AppColors.accent3 : AppColors.accent.withOpacity(0.4), width: 1.5),
        ),
        child: Row(
          children: [
            // Sign emoji
            ScaleTransition(
              scale: _pulse,
              child: Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isCorrect
                      ? [AppColors.accent3.withOpacity(0.3), AppColors.accent3.withOpacity(0.1)]
                      : [AppColors.accent.withOpacity(0.2), AppColors.accent2.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _isCorrect ? AppColors.accent3 : AppColors.accent, width: 1.5),
                ),
                child: Center(child: Text(_signEmoji[_targetLetter] ?? '🤟', style: const TextStyle(fontSize: 28))),
              ),
            ),
            const SizedBox(width: 16),
            // Label
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('SIGN THIS LETTER', style: TextStyle(color: AppColors.muted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(_targetLetter, style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: _isCorrect ? AppColors.accent3 : AppColors.accent, height: 1)),
              ]),
            ),
            // Accuracy
            if (_attempts > 0)
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${(_score / _attempts * 100).round()}%', style: const TextStyle(color: AppColors.accent3, fontSize: 20, fontWeight: FontWeight.w900)),
                const Text('accuracy', style: TextStyle(color: AppColors.muted, fontSize: 10)),
              ]),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Skip
          GestureDetector(
            onTap: _isPracticing ? _skipLetter : null,
            child: Container(
              width: 56, height: 52,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.skip_next_rounded, color: AppColors.muted),
            ),
          ),
          const SizedBox(width: 10),
          // Main button
          Expanded(
            child: GestureDetector(
              onTap: _isPracticing ? _stopPractice : _startPractice,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isPracticing
                      ? [Colors.red.shade700, Colors.red.shade500]
                      : [AppColors.accent, AppColors.accent2],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: (_isPracticing ? Colors.red : AppColors.accent).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_isPracticing ? Icons.stop_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    Text(_isPracticing ? 'Stop Practice' : 'Start Practice', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Stat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 9)),
    ],
  );
}
