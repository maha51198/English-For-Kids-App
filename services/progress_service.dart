import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  static const _key = 'memvocab_progress_v1';

  static Future<Map<String, dynamic>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  static Future<int> getStars(String catId, int level) async {
    final data = await loadAll();
    final cat = data[catId];
    if (cat is! Map) return 0;
    return (cat[level.toString()] as num?)?.toInt() ?? 0;
  }

  static Future<void> setStars(String catId, int level, int stars) async {
    final prefs = await SharedPreferences.getInstance();
    final data = await loadAll();
    final cat = (data[catId] is Map)
        ? Map<String, dynamic>.from(data[catId] as Map)
        : <String, dynamic>{};
    final current = (cat[level.toString()] as num?)?.toInt() ?? 0;
    if (stars > current) {
      cat[level.toString()] = stars;
      data[catId] = cat;
      await prefs.setString(_key, jsonEncode(data));
    }
  }
}