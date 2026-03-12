import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_colors.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen>
    with TickerProviderStateMixin {

  int _tabIndex = 0;
  String? _selectedLetter;

  static const int _totalQuestions = 10;
  List<Map<String, String>> _quizQuestions = [];
  int _currentQ = 0;
  int _score = 0;
  List<String> _options = [];
  String? _selectedAnswer;
  bool _answered = false;
  bool _showResults = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;

  static const List<Map<String, String>> _signs = [
    {'letter': 'A', 'emoji': '✊', 'desc': 'Make a fist. The thumb rests on the side of the index finger.'},
    {'letter': 'B', 'emoji': '🖐️', 'desc': 'Hold all four fingers straight up. Press the thumb flat into your palm.'},
    {'letter': 'C', 'emoji': '🤏', 'desc': 'Curve your fingers and thumb into a C shape — like grabbing a cup.'},
    {'letter': 'D', 'emoji': '👆', 'desc': 'Point index finger straight up. Touch thumb to the middle, ring, and pinky fingers.'},
    {'letter': 'E', 'emoji': '🤜', 'desc': 'Curl all four fingers down toward the palm. Tuck the thumb under the bent fingers.'},
    {'letter': 'F', 'emoji': '👌', 'desc': 'Touch the tip of the index finger to the thumb to form a circle. Hold other three fingers straight up.'},
    {'letter': 'G', 'emoji': '👉', 'desc': 'Point the index finger sideways. The thumb also points out to the side parallel to it.'},
    {'letter': 'H', 'emoji': '🤞', 'desc': 'Hold the index and middle fingers together pointing sideways. The thumb is tucked in.'},
    {'letter': 'I', 'emoji': '🤙', 'desc': 'Raise only the pinky finger. Keep all other fingers curled in a fist.'},
    {'letter': 'J', 'emoji': '🤙', 'desc': 'Start with the pinky raised like the letter I, then trace a J curve downward in the air.'},
    {'letter': 'K', 'emoji': '✌️', 'desc': 'Extend index and middle fingers in a V shape. Place the thumb pointing up between them.'},
    {'letter': 'L', 'emoji': '🤙', 'desc': 'Point the index finger straight up and stick the thumb straight out to make an L shape.'},
    {'letter': 'M', 'emoji': '✊', 'desc': 'Fold three fingers — index, middle, ring — over the thumb. The pinky is tucked in.'},
    {'letter': 'N', 'emoji': '✊', 'desc': 'Fold two fingers — index and middle — over the thumb. Ring and pinky are tucked in.'},
    {'letter': 'O', 'emoji': '👌', 'desc': 'Bring all fingers and the thumb together in a circular shape, like forming the letter O.'},
    {'letter': 'P', 'emoji': '👇', 'desc': 'Hold the index and middle fingers pointing downward. Stick the thumb out to the side.'},
    {'letter': 'Q', 'emoji': '👇', 'desc': 'Point the index finger and thumb straight downward, like a G shape flipped down.'},
    {'letter': 'R', 'emoji': '🤞', 'desc': 'Cross the index finger over the middle finger. The other fingers are folded down.'},
    {'letter': 'S', 'emoji': '✊', 'desc': 'Make a fist with the thumb resting across the front of all four fingers.'},
    {'letter': 'T', 'emoji': '✊', 'desc': 'Tuck the thumb between the index and middle fingers while making a fist.'},
    {'letter': 'U', 'emoji': '✌️', 'desc': 'Hold index and middle fingers together pointing straight up — like a peace sign but closed.'},
    {'letter': 'V', 'emoji': '✌️', 'desc': 'Spread the index and middle fingers apart into a V shape — like a peace or victory sign.'},
    {'letter': 'W', 'emoji': '🤟', 'desc': 'Spread three fingers apart — index, middle, and ring. The thumb and pinky touch together.'},
    {'letter': 'X', 'emoji': '☝️', 'desc': 'Curl only the index finger into a bent hook shape. All other fingers are in a fist.'},
    {'letter': 'Y', 'emoji': '🤙', 'desc': 'Extend thumb and pinky finger outward. Keep index, middle, and ring fingers folded in.'},
    {'letter': 'Z', 'emoji': '☝️', 'desc': 'Use the index finger to draw a Z shape in the air — three strokes like the letter.'},
  ];

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn));
    _startQuiz();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _startQuiz() {
    final shuffled = List<Map<String, String>>.from(_signs)..shuffle();
    _quizQuestions = shuffled.take(_totalQuestions).toList();
    _currentQ = 0;
    _score = 0;
    _answered = false;
    _selectedAnswer = null;
    _showResults = false;
    _generateOptions();
  }

  void _generateOptions() {
    final correct = _quizQuestions[_currentQ]['letter']!;
    final allLetters = _signs.map((s) => s['letter']!).toList();
    allLetters.remove(correct);
    allLetters.shuffle();
    _options = [...allLetters.take(3), correct]..shuffle();
  }

  void _selectAnswer(String letter) {
    if (_answered) return;
    final correct = _quizQuestions[_currentQ]['letter']!;
    setState(() {
      _selectedAnswer = letter;
      _answered = true;
      if (letter == correct) {
        _score++;
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.heavyImpact();
        _shakeController.forward(from: 0);
      }
    });
  }

  void _nextQuestion() {
    if (_currentQ + 1 >= _totalQuestions) {
      setState(() => _showResults = true);
    } else {
      setState(() {
        _currentQ++;
        _answered = false;
        _selectedAnswer = null;
        _generateOptions();
      });
    }
  }

  void _resetQuiz() => setState(() => _startQuiz());

  Map<String, dynamic> _getGrade() {
    if (_score == 10) return {'grade': 'S', 'trophy': '🏆', 'title': 'Perfect Score!',    'color': AppColors.accent3};
    if (_score >= 8)  return {'grade': 'A', 'trophy': '🌟', 'title': 'Excellent!',         'color': AppColors.accent};
    if (_score >= 6)  return {'grade': 'B', 'trophy': '👍', 'title': 'Good Job!',          'color': AppColors.accent2};
    if (_score >= 4)  return {'grade': 'C', 'trophy': '📚', 'title': 'Keep Learning!',     'color': const Color(0xFFF59E0B)};
    return               {'grade': 'F', 'trophy': '💪', 'title': 'Keep Practicing!',   'color': const Color(0xFFEF4444)};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(child: _tabIndex == 0 ? _buildLearnTab() : _buildQuizTab()),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('EDUCATION', style: TextStyle(fontSize: 11, letterSpacing: 1.5, color: AppColors.accent, fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        const Text('Learn Sign Language', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textColor)),
        const SizedBox(height: 3),
        Text(
          _tabIndex == 0 ? 'Tap a letter to learn the sign.' : '10 questions — look at the hand sign emoji and pick the correct letter.',
          style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5),
        ),
      ]),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        _TabBtn(label: '📖  Learn', active: _tabIndex == 0, onTap: () => setState(() => _tabIndex = 0)),
        _TabBtn(label: '🧠  Quiz',  active: _tabIndex == 1, onTap: () => setState(() => _tabIndex = 1)),
      ]),
    );
  }

  // ── LEARN TAB ──────────────────────────────────────────────
  Widget _buildLearnTab() {
    return CustomScrollView(slivers: [
      if (_selectedLetter != null) SliverToBoxAdapter(child: _buildLetterDetail()),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        sliver: SliverToBoxAdapter(
          child: const Text('TAP A SIGN TO LEARN IT',
              style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: AppColors.muted, fontWeight: FontWeight.w600)),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1,
          ),
          delegate: SliverChildBuilderDelegate((context, i) {
            final item = _signs[i];
            final isSelected = _selectedLetter == item['letter'];
            return GestureDetector(
              onTap: () => setState(() => _selectedLetter = item['letter']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent.withOpacity(0.15) : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isSelected ? AppColors.accent.withOpacity(0.6) : AppColors.border, width: isSelected ? 2 : 1),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(item['emoji']!, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(item['letter']!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900,
                      color: isSelected ? AppColors.accent : AppColors.textColor)),
                ]),
              ),
            );
          }, childCount: _signs.length),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ]);
  }

  Widget _buildLetterDetail() {
    final item = _signs.firstWhere((e) => e['letter'] == _selectedLetter);
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.accent.withOpacity(0.10), AppColors.accent2.withOpacity(0.06)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          width: 76, height: 76,
          decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.accent.withOpacity(0.35))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(item['emoji']!, style: const TextStyle(fontSize: 26)),
            Text(item['letter']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.accent)),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Sign Letter ${item['letter']}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textColor)),
          const SizedBox(height: 5),
          Text(item['desc']!, style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.5)),
        ])),
      ]),
    );
  }

  // ── QUIZ TAB ───────────────────────────────────────────────
  Widget _buildQuizTab() {
    if (_showResults) return _buildResultsScreen();
    final q = _quizQuestions[_currentQ];
    final correct = q['letter']!;

    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (context, child) => Transform.translate(
        offset: Offset(sin(_shakeAnim.value * pi * 6) * 8, 0), child: child),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Progress
          Row(children: [
            Text('Q ${_currentQ + 1} / $_totalQuestions',
                style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500)),
            const SizedBox(width: 12),
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: (_currentQ + 1) / _totalQuestions,
                backgroundColor: AppColors.surface,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                minHeight: 6,
              ),
            )),
            const SizedBox(width: 12),
            Text('$_score pts', style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w700)),
          ]),

          const SizedBox(height: 20),

          // Question card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppColors.accent.withOpacity(0.25)),
                ),
                child: const Text('❓  SIGN LANGUAGE QUIZ',
                    style: TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w700, letterSpacing: 1)),
              ),
              const SizedBox(height: 20),
              // Show the CORRECT answer emoji as the visual question
              Container(
                width: 130, height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withOpacity(0.07),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3), width: 2),
                ),
                child: Center(
                  child: Text(q['emoji']!, style: const TextStyle(fontSize: 62)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Which letter is this sign?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: AppColors.textColor,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Select the correct letter from the options below',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ]),
          ),

          const SizedBox(height: 16),

          // 4 Options
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.0,
            children: _options.map((letter) => _buildOptionBtn(letter, correct)).toList(),
          ),

          const SizedBox(height: 14),
          if (_answered) _buildFeedback(correct),
          const SizedBox(height: 14),

          // Next button
          if (_answered)
            GestureDetector(
              onTap: _nextQuestion,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFF06B6D4)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: Text(
                  _currentQ + 1 >= _totalQuestions ? '🏁  See Results' : 'Next Question →',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.bg),
                )),
              ),
            ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _buildOptionBtn(String letter, String correct) {
    Color borderColor = AppColors.border;
    Color bgColor = AppColors.surface;
    Color textColor = AppColors.accent;
    String icon = '';

    if (_answered) {
      if (letter == correct && _selectedAnswer == correct) {
        borderColor = AppColors.accent3; bgColor = AppColors.accent3.withOpacity(0.12);
        textColor = AppColors.accent3; icon = '✓';
      } else if (letter == _selectedAnswer && _selectedAnswer != correct) {
        borderColor = const Color(0xFFEF4444); bgColor = const Color(0xFFEF4444).withOpacity(0.10);
        textColor = const Color(0xFFEF4444); icon = '✗';
      } else if (letter == correct) {
        borderColor = AppColors.accent3.withOpacity(0.5); bgColor = AppColors.accent3.withOpacity(0.06);
        textColor = AppColors.accent3; icon = '✓';
      }
    }

    return GestureDetector(
      onTap: _answered ? null : () => _selectAnswer(letter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Stack(children: [
          Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(letter, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textColor)),
            Text('Letter $letter', style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.6), fontWeight: FontWeight.w500)),
          ])),
          if (icon.isNotEmpty)
            Positioned(top: 8, right: 10,
                child: Text(icon, style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.w900))),
        ]),
      ),
    );
  }

  Widget _buildFeedback(String correct) {
    final isCorrect = _selectedAnswer == correct;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCorrect ? AppColors.accent3.withOpacity(0.12) : const Color(0xFFEF4444).withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCorrect ? AppColors.accent3.withOpacity(0.4) : const Color(0xFFEF4444).withOpacity(0.4)),
      ),
      child: Row(children: [
        Text(isCorrect ? '✅' : '❌', style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(child: Text(
          isCorrect ? 'Correct! "$correct" is the right answer!' : 'Wrong! The correct answer was "$correct".',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: isCorrect ? AppColors.accent3 : const Color(0xFFFCA5A5)),
        )),
      ]),
    );
  }

  // ── RESULTS SCREEN ─────────────────────────────────────────
  Widget _buildResultsScreen() {
    final g = _getGrade();
    final wrong = _totalQuestions - _score;
    final accuracy = (_score / _totalQuestions * 100).toStringAsFixed(0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          Text(g['trophy'], style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text(g['title'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textColor)),
          const SizedBox(height: 4),
          const Text('Quiz Complete! Here\'s how you did.', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 24),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(colors: [AppColors.accent, AppColors.accent2]).createShader(b),
            child: Text('$_score', style: const TextStyle(fontSize: 80, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
          ),
          const Text('out of 10 questions', style: TextStyle(fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: (g['color'] as Color).withOpacity(0.12),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: (g['color'] as Color).withOpacity(0.4)),
            ),
            child: Text('Grade: ${g['grade']}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: g['color'] as Color)),
          ),
          const SizedBox(height: 24),
          Row(children: [
            _StatCard(value: '$_score', label: 'Correct', color: AppColors.accent3),
            const SizedBox(width: 10),
            _StatCard(value: '$wrong', label: 'Wrong', color: const Color(0xFFEF4444)),
            const SizedBox(width: 10),
            _StatCard(value: '$accuracy%', label: 'Accuracy', color: AppColors.accent),
          ]),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _resetQuiz,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFF06B6D4)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(child: Text('🔄  Try Again',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.bg))),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() { _tabIndex = 0; _showResults = false; }),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(child: Text('📖  Go to Learn',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textColor))),
            ),
          ),
        ]),
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.accent.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: active ? Border.all(color: AppColors.accent.withOpacity(0.4)) : null,
          ),
          child: Center(child: Text(label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: active ? AppColors.accent : AppColors.muted))),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatCard({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}
