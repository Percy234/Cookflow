import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/hive_service.dart';

class HistoryEntry {
  final String recipeId;
  final DateTime executedAt;

  HistoryEntry({required this.recipeId, required this.executedAt});

  Map<String, dynamic> toJson() => {
        'recipeId': recipeId,
        'executedAt': executedAt.toIso8601String(),
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        recipeId: json['recipeId'] as String,
        executedAt: DateTime.parse(json['executedAt'] as String),
      );
}

class HistoryProvider extends ChangeNotifier {
  static const String _key = 'history';

  List<HistoryEntry> _entries = [];

  /// Sorted newest-first
  List<HistoryEntry> get entries => List.unmodifiable(_entries);

  HistoryProvider() {
    _load();
  }

  void _load() {
    final stored = HiveService.settingsBox.get(_key);
    if (stored is String) {
      try {
        final decoded = jsonDecode(stored) as List<dynamic>;
        _entries = decoded
            .map((e) => HistoryEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList()
          ..sort((a, b) => b.executedAt.compareTo(a.executedAt));
      } catch (_) {
        _entries = [];
      }
    }
  }

  Future<void> _save() async {
    final encoded = jsonEncode(_entries.map((e) => e.toJson()).toList());
    await HiveService.settingsBox.put(_key, encoded);
  }

  Future<void> addEntry(String recipeId) async {
    _entries.insert(
      0,
      HistoryEntry(recipeId: recipeId, executedAt: DateTime.now()),
    );
    // Keep at most 200 entries
    if (_entries.length > 200) {
      _entries = _entries.take(200).toList();
    }
    await _save();
    notifyListeners();
  }

  Future<void> removeEntryAt(int index) async {
    if (index >= 0 && index < _entries.length) {
      _entries.removeAt(index);
      await _save();
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    _entries.clear();
    await _save();
    notifyListeners();
  }
}
