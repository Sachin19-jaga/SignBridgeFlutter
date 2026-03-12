import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_colors.dart';

class FeaturesScreen extends StatefulWidget {
  const FeaturesScreen({super.key});
  @override
  State<FeaturesScreen> createState() => _FeaturesScreenState();
}

class _FeaturesScreenState extends State<FeaturesScreen>
    with TickerProviderStateMixin {

  final TextEditingController _textController = TextEditingController();
  String _inputText = '';
  int _currentIndex = 0;
  bool _autoPlay = false;
  bool _isAutoPlaying = false;

  late AnimationController _popController;
  late Animation<double> _popScale;
  late AnimationController _glowController;
  late Animation<double> _glowAnim;
  dynamic _autoPlayTimer; // Timer for autoplay

  static const Map<String, String> _signEmojis = {
    'A': '✊', 'B': '🖐️', 'C': '🤏', 'D': '👆', 'E': '🤜',
    'F': '👌', 'G': '👉', 'H': '🤞', 'I': '🤙', 'J': '🤙',
    'K': '✌️', 'L': '🤙', 'M': '✊', 'N': '✊', 'O': '👌',
    'P': '👇', 'Q': '👇', 'R': '🤞', 'S': '✊', 'T': '✊',
    'U': '✌️', 'V': '✌️', 'W': '🤟', 'X': '☝️', 'Y': '🤙',
    'Z': '☝️', ' ': '▪️',
    '0': '👌', '1': '☝️', '2': '✌️', '3': '🤟', '4': '🖐️',
    '5': '✋', '6': '🤙', '7': '🤞', '8': '🤌', '9': '👌',
  };

  static const Map<String, String> _signDesc = {
    'A': 'Make a fist. Thumb on the side.',
    'B': 'Four fingers straight up, thumb in palm.',
    'C': 'Curve fingers into a C shape.',
    'D': 'Index up, thumb touches other fingers.',
    'E': 'Curl all fingers, thumb tucked under.',
    'F': 'Index touches thumb, others up.',
    'G': 'Index points sideways, thumb parallel.',
    'H': 'Index & middle point sideways together.',
    'I': 'Pinky raised, fist for others.',
    'J': 'Pinky raised, trace J in air.',
    'K': 'Index & middle in V, thumb between.',
    'L': 'Index up, thumb out — L shape.',
    'M': 'Three fingers folded over thumb.',
    'N': 'Two fingers folded over thumb.',
    'O': 'All fingers form a circle — O shape.',
    'P': 'Like K but pointing downward.',
    'Q': 'Like G but pointing downward.',
    'R': 'Cross index over middle finger.',
    'S': 'Fist with thumb over all fingers.',
    'T': 'Thumb tucked between index & middle.',
    'U': 'Index & middle up together.',
    'V': 'Index & middle spread apart — V sign.',
    'W': 'Three fingers spread — index, middle, ring.',
    'X': 'Index finger curled into a hook.',
    'Y': 'Thumb & pinky out, others folded.',
    'Z': 'Index traces a Z in the air.',
    ' ': 'Space between words.',
  };

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _popScale = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _popController, curve: Curves.elasticOut));

    _glowController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _popController.dispose();
    _glowController.dispose();
    _textController.dispose();
    super.dispose();
  }

  List<String> get _letters => _inputText.split('');

  void _startAutoPlay() {
    if (_letters.isEmpty) return;
    setState(() { _isAutoPlaying = true; _currentIndex = 0; });
    _popController.forward(from: 0);
    _autoPlayTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (!mounted || !_isAutoPlaying) { timer.cancel(); return; }
      if (_currentIndex < _letters.length - 1) {
        setState(() => _currentIndex++);
        _popController.forward(from: 0);
        HapticFeedback.selectionClick();
      } else {
        timer.cancel();
        setState(() => _isAutoPlaying = false);
      }
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    setState(() => _isAutoPlaying = false);
  }

  void _convert() {
    final text = _textController.text.trim().toUpperCase();
    if (text.isEmpty) return;
    setState(() {
      _inputText = text;
      _currentIndex = 0;
    });
    _popController.forward(from: 0);
    HapticFeedback.lightImpact();
    if (_autoPlay) {
      Future.delayed(const Duration(milliseconds: 300), _startAutoPlay);
    }
  }

  void _selectLetter(int i) {
    setState(() => _currentIndex = i);
    _popController.forward(from: 0);
    HapticFeedback.selectionClick();
  }

  void _prev() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _popController.forward(from: 0);
      HapticFeedback.selectionClick();
    }
  }

  void _next() {
    if (_currentIndex < _letters.length - 1) {
      setState(() => _currentIndex++);
      _popController.forward(from: 0);
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _buildInputCard(),
                const SizedBox(height: 16),
                if (_inputText.isNotEmpty) ...[
                  _buildBigSignDisplay(),
                  const SizedBox(height: 16),
                  _buildLetterRow(),
                  const SizedBox(height: 16),
                  _buildNavButtons(),
                  const SizedBox(height: 16),
                  _buildInfoCard(),
                ] else
                  _buildEmptyState(),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent3.withOpacity(0.12),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppColors.accent3.withOpacity(0.3)),
            ),
            child: const Text('🔤  TEXT TO SIGN',
                style: TextStyle(fontSize: 10, color: AppColors.accent3,
                    fontWeight: FontWeight.w700, letterSpacing: 1)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Text('NEW', style: TextStyle(fontSize: 9,
                color: AppColors.accent, fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 8),
        const Text('Sign Language Translator',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                color: AppColors.textColor)),
        const SizedBox(height: 3),
        const Text('Type any text and see it translated into ASL hand signs letter by letter.',
            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5)),
      ]),
    );
  }

  // ── INPUT CARD ─────────────────────────────────────────────
  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('ENTER YOUR TEXT',
            style: TextStyle(fontSize: 10, letterSpacing: 1.2,
                color: AppColors.muted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: AppColors.textColor,
                    fontSize: 16, fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                  hintText: 'e.g. HELLO WORLD',
                  hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: InputBorder.none,
                ),
                textCapitalization: TextCapitalization.characters,
                onSubmitted: (_) => _convert(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _convert,
            child: Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.accent, Color(0xFF06B6D4)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(
                    color: AppColors.accent.withOpacity(0.35),
                    blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.translate_rounded,
                  color: AppColors.bg, size: 26),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        // ── AUTOPLAY CHECKBOX (compact) ────────────────────
        Row(mainAxisSize: MainAxisSize.min, children: [
          Checkbox(
            value: _autoPlay,
            onChanged: (val) {
              setState(() => _autoPlay = val ?? false);
              if (!_autoPlay) _stopAutoPlay();
              HapticFeedback.selectionClick();
            },
            activeColor: AppColors.accent,
            side: const BorderSide(color: AppColors.muted, width: 1.5),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          const Text('Auto-play signs',
              style: TextStyle(fontSize: 12, color: AppColors.muted)),
        ]),
        if (_inputText.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.accent3, size: 14),
            const SizedBox(width: 6),
            Text('Showing ${_letters.length} sign${_letters.length == 1 ? '' : 's'} for "$_inputText"',
                style: const TextStyle(fontSize: 11,
                    color: AppColors.accent3, fontWeight: FontWeight.w500)),
          ]),
        ],
      ]),
    );
  }

  // ── BIG SIGN DISPLAY ───────────────────────────────────────
  Widget _buildBigSignDisplay() {
    if (_letters.isEmpty) return const SizedBox();
    final ch = _letters[_currentIndex];
    final emoji = _signEmojis[ch] ?? '❓';
    final isSpace = ch == ' ';

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.accent.withOpacity(0.3 + _glowAnim.value * 0.3),
            width: 1.5,
          ),
          boxShadow: [BoxShadow(
            color: AppColors.accent.withOpacity(0.05 + _glowAnim.value * 0.08),
            blurRadius: 30, spreadRadius: 2,
          )],
        ),
        child: child,
      ),
      child: Column(children: [
        // Position indicator
        Text('${_currentIndex + 1} / ${_letters.length}',
            style: const TextStyle(fontSize: 11, color: AppColors.muted,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 16),

        // Big emoji
        AnimatedBuilder(
          animation: _popController,
          builder: (_, child) => Transform.scale(
              scale: _popScale.value, child: child),
          child: isSpace
              ? Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.bg,
                    border: Border.all(color: AppColors.border, width: 2),
                  ),
                  child: const Center(
                    child: Text('SPACE',
                        style: TextStyle(fontSize: 14,
                            color: AppColors.muted, fontWeight: FontWeight.w700)),
                  ),
                )
              : Text(emoji, style: const TextStyle(fontSize: 100)),
        ),

        const SizedBox(height: 16),

        // Letter name
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
              colors: [AppColors.accent, AppColors.accent2]).createShader(b),
          child: Text(
            isSpace ? 'SPACE' : 'Letter $ch',
            style: const TextStyle(
              fontSize: 32, fontWeight: FontWeight.w900,
              color: Colors.white, letterSpacing: 3,
            ),
          ),
        ),
      ]),
    );
  }

  // ── LETTER ROW ─────────────────────────────────────────────
  Widget _buildLetterRow() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('TAP A LETTER TO SEE ITS SIGN',
            style: TextStyle(fontSize: 10, letterSpacing: 1.1,
                color: AppColors.muted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: List.generate(_letters.length, (i) {
            final ch = _letters[i];
            final isSelected = i == _currentIndex;
            final emoji = _signEmojis[ch];

            return GestureDetector(
              onTap: () => _selectLetter(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent.withOpacity(0.15)
                      : AppColors.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accent.withOpacity(0.7)
                        : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: AppColors.accent.withOpacity(0.25),
                          blurRadius: 10)]
                      : null,
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  Text(emoji ?? '?',
                      style: TextStyle(fontSize: ch == ' ' ? 10 : 22)),
                  const SizedBox(height: 4),
                  Text(ch == ' ' ? '⎵' : ch,
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w900,
                        color: isSelected ? AppColors.accent : AppColors.muted,
                      )),
                ]),
              ),
            );
          }),
        ),
      ]),
    );
  }

  // ── NAV BUTTONS ────────────────────────────────────────────
  Widget _buildNavButtons() {
    // If autoplaying, show a Stop button instead
    if (_isAutoPlaying) {
      return GestureDetector(
        onTap: _stopAutoPlay,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.stop_rounded, color: Color(0xFFEF4444), size: 22),
            SizedBox(width: 8),
            Text('Stop Auto-play',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                    color: Color(0xFFEF4444))),
          ]),
        ),
      );
    }

    final canPrev = _currentIndex > 0;
    final canNext = _currentIndex < _letters.length - 1;

    return Row(children: [
      // Prev
      Expanded(
        child: GestureDetector(
          onTap: canPrev ? _prev : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: canPrev ? AppColors.surface : AppColors.surface.withOpacity(0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: canPrev ? AppColors.border : AppColors.border.withOpacity(0.3)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.arrow_back_ios_rounded, size: 16,
                  color: canPrev ? AppColors.textColor : AppColors.muted),
              const SizedBox(width: 6),
              Text('Prev', style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: canPrev ? AppColors.textColor : AppColors.muted)),
            ]),
          ),
        ),
      ),
      const SizedBox(width: 12),
      // Counter pill
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.accent.withOpacity(0.25)),
        ),
        child: Text('${_currentIndex + 1} / ${_letters.length}',
            style: const TextStyle(fontSize: 13, color: AppColors.accent,
                fontWeight: FontWeight.w700)),
      ),
      const SizedBox(width: 12),
      // Next
      Expanded(
        child: GestureDetector(
          onTap: canNext ? _next : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: canNext
                  ? const LinearGradient(colors: [AppColors.accent, Color(0xFF06B6D4)])
                  : null,
              color: canNext ? null : AppColors.surface.withOpacity(0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: canNext ? Colors.transparent : AppColors.border.withOpacity(0.3)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Next', style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: canNext ? AppColors.bg : AppColors.muted)),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_ios_rounded, size: 16,
                  color: canNext ? AppColors.bg : AppColors.muted),
            ]),
          ),
        ),
      ),
    ]);
  }

  // ── INFO CARD (description of current sign) ────────────────
  Widget _buildInfoCard() {
    if (_letters.isEmpty) return const SizedBox();
    final ch = _letters[_currentIndex];
    final desc = _signDesc[ch] ?? 'No description available.';
    final emoji = _signEmojis[ch] ?? '❓';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.accent.withOpacity(0.07),
          AppColors.accent2.withOpacity(0.04),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.2)),
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ch == ' ' ? 'SPACE' : 'How to sign "$ch"',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppColors.textColor)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 12,
              color: AppColors.muted, height: 1.5)),
        ])),
      ]),
    );
  }

  // ── EMPTY STATE ────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        const Text('🤟', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        const Text('Start Translating',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                color: AppColors.textColor)),
        const SizedBox(height: 8),
        const Text('Type any word above and tap the\ntranslate button to see ASL signs.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.6)),
        const SizedBox(height: 24),
        // Example words
        Wrap(
          spacing: 8, runSpacing: 8,
          alignment: WrapAlignment.center,
          children: ['HELLO', 'WORLD', 'LOVE', 'THANKS', 'YES', 'NO'].map((word) =>
            GestureDetector(
              onTap: () {
                _textController.text = word;
                _convert();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: Text(word, style: const TextStyle(
                    fontSize: 12, color: AppColors.accent,
                    fontWeight: FontWeight.w600)),
              ),
            ),
          ).toList(),
        ),
      ]),
    );
  }
}
