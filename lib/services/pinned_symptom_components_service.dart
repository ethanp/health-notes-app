import 'dart:convert';

import 'package:health_notes/models/pinned_symptom_components.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinnedSymptomComponentsService {
  static const _storageKey = 'pinned_symptom_components';

  static Future<PinnedSymptomComponents> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) {
      return PinnedSymptomComponents.empty;
    }
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return PinnedSymptomComponents.fromJson(json);
    } catch (_) {
      return PinnedSymptomComponents.empty;
    }
  }

  static Future<void> save(PinnedSymptomComponents pinned) async {
    final prefs = await SharedPreferences.getInstance();
    final json = pinned.toJson();
    await prefs.setString(_storageKey, jsonEncode(json));
  }
}


