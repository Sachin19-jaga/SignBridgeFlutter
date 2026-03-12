import 'package:flutter/material.dart';
import '../models/app_colors.dart';
import 'recognize_screen.dart';
import 'features_screen.dart';
import 'learn_screen.dart';
import 'practice_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    RecognizeScreen(),
    FeaturesScreen(),
    PracticeScreen(),
    LearnScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.camera_alt_rounded,     label: 'Recognize', index: 0, selected: _selectedIndex, onTap: () => setState(() => _selectedIndex = 0)),
                _NavItem(icon: Icons.translate_rounded,      label: 'Translate', index: 1, selected: _selectedIndex, onTap: () => setState(() => _selectedIndex = 1)),
                _NavItem(icon: Icons.fitness_center_rounded, label: 'Practice',  index: 2, selected: _selectedIndex, onTap: () => setState(() => _selectedIndex = 2)),
                _NavItem(icon: Icons.school_rounded,         label: 'Learn',     index: 3, selected: _selectedIndex, onTap: () => setState(() => _selectedIndex = 3)),
                _NavItem(icon: Icons.history_rounded,        label: 'History',   index: 4, selected: _selectedIndex, onTap: () => setState(() => _selectedIndex = 4)),
                _NavItem(icon: Icons.settings_rounded,       label: 'Settings',  index: 5, selected: _selectedIndex, onTap: () => setState(() => _selectedIndex = 5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index, selected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.index, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = index == selected;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? AppColors.accent : AppColors.muted, size: 22),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(color: isActive ? AppColors.accent : AppColors.muted, fontSize: 9, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
