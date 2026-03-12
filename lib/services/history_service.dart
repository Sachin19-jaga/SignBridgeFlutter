import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryEntry {
  final String text;
  final DateTime timestamp;
  final int letterCount;

  HistoryEntry({required this.text, required this.timestamp, required this.letterCount});

  Map<String, dynamic> toJson() => {
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'letterCount': letterCount,
  };

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
    text: j['text'],
    timestamp: DateTime.parse(j['timestamp']),
    letterCount: j['letterCount'],
  );
}

class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  late SharedPreferences _prefs;
  static const _key = 'transcript_history';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveEntry(String text) async {
    if (text.trim().isEmpty) return;
    final entries = await getEntries();
    entries.insert(0, HistoryEntry(
      text: text.trim(),
      timestamp: DateTime.now(),
      letterCount: text.trim().length,
    ));
    // Keep max 50 entries
    final trimmed = entries.take(50).toList();
    await _prefs.setString(_key, json.encode(trimmed.map((e) => e.toJson()).toList()));
  }

  Future<List<HistoryEntry>> getEntries() async {
    try {
      final raw = _prefs.getString(_key);
      if (raw == null) return [];
      final list = json.decode(raw) as List;
      return list.map((e) => HistoryEntry.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteEntry(int index) async {
    final entries = await getEntries();
    entries.removeAt(index);
    await _prefs.setString(_key, json.encode(entries.map((e) => e.toJson()).toList()));
  }

  Future<void> clearAll() async {
    await _prefs.remove(_key);
  }
}
