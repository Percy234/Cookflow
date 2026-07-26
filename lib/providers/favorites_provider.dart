import 'package:flutter/foundation.dart';
import '../services/hive_service.dart';

class FavoritesProvider extends ChangeNotifier {
  static const String _key = 'favorites';

  List<String> _favoriteIds = [];

  List<String> get favoriteIds => List.unmodifiable(_favoriteIds);

  FavoritesProvider() {
    _load();
  }

  void _load() {
    final stored = HiveService.settingsBox.get(_key);
    if (stored is List) {
      _favoriteIds = stored.whereType<String>().toList();
    }
  }

  Future<void> _save() async {
    await HiveService.settingsBox.put(_key, List<String>.from(_favoriteIds));
  }

  bool isFavorite(String recipeId) => _favoriteIds.contains(recipeId);

  Future<void> toggleFavorite(String recipeId) async {
    if (_favoriteIds.contains(recipeId)) {
      _favoriteIds.remove(recipeId);
    } else {
      _favoriteIds.add(recipeId);
    }
    await _save();
    notifyListeners();
  }

  Future<void> removeFavorite(String recipeId) async {
    _favoriteIds.remove(recipeId);
    await _save();
    notifyListeners();
  }
}
