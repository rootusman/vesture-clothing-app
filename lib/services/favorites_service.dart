import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  static const String _key = 'favorites_v1';

  final ValueNotifier<Set<String>> favoritesListenable = ValueNotifier<Set<String>>(<String>{});

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    final String? raw = _prefs!.getString(_key);
    if (raw != null) {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      favoritesListenable.value = decoded.map((dynamic e) => e as String).toSet();
    }
  }

  Set<String> get ids => Set<String>.from(favoritesListenable.value);

  bool isFavorite(String productId) => favoritesListenable.value.contains(productId);

  Future<void> toggle(String productId) async {
    final Set<String> next = Set<String>.from(favoritesListenable.value);
    if (!next.add(productId)) {
      next.remove(productId);
    }
    favoritesListenable.value = next;
    await _persist();
  }

  Future<void> _persist() async {
    if (_prefs == null) return;
    final String raw = jsonEncode(favoritesListenable.value.toList());
    await _prefs!.setString(_key, raw);
  }
}
