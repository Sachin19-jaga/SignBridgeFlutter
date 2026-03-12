import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_colors.dart';
import '../services/history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _history = HistoryService();
  List<HistoryEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _history.init();
    final entries = await _history.getEntries();
    setState(() { _entries = entries; _loading = false; });
  }

  Future<void> _delete(int index) async {
    await _history.deleteEntry(index);
    await _load();
    HapticFeedback.mediumImpact();
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Clear History', style: TextStyle(color: AppColors.textColor)),
        content: const Text('Delete all saved transcripts?', style: TextStyle(color: AppColors.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: AppColors.muted))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete All', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await _history.clearAll();
      await _load();
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
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
                      color: AppColors.accent2.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.history_rounded, color: AppColors.accent2, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textColor)),
                        Text('Your saved transcripts', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (_entries.isNotEmpty)
                    GestureDetector(
                      onTap: _clearAll,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: const Text('Clear All', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : _entries.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _entries.length,
                      itemBuilder: (ctx, i) => _buildEntry(_entries[i], i),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Text('📝', style: TextStyle(fontSize: 48)),
          ),
          const SizedBox(height: 20),
          const Text('No history yet', style: TextStyle(color: AppColors.textColor, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Transcripts from Recognize screen\nwill be saved here automatically', style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildEntry(HistoryEntry entry, int index) {
    return Dismissible(
      key: Key('entry_$index'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _delete(index),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.red),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${entry.letterCount} letters', style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                Text(_formatTime(entry.timestamp), style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                const SizedBox(width: 8),
                // Copy button
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: entry.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard!'), backgroundColor: AppColors.surface2, duration: Duration(seconds: 1)),
                    );
                    HapticFeedback.lightImpact();
                  },
                  child: const Icon(Icons.copy_rounded, color: AppColors.muted, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              entry.text,
              style: const TextStyle(color: AppColors.textColor, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 1.2),
            ),
            const SizedBox(height: 6),
            const Text('← Swipe to delete', style: TextStyle(color: AppColors.muted, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
