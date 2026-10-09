import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/stillness_data.dart';

/// Persistence. The web app used `localStorage` under `stillness.v2` with a
/// migration read from `stillness.v1`. On Android we keep the identical
/// versioned-JSON-document model in [SharedPreferences] — one key, one string,
/// same validation path (`StillnessData.clean`). Malformed data can never
/// crash the app: a decode failure simply yields a fresh document.
class StillnessStore {
  const StillnessStore._();

  static Future<StillnessData> load() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(kStorageKey) ?? sp.getString(kLegacyKey);
      if (raw == null || raw.isEmpty) return StillnessData();
      return StillnessData.clean(jsonDecode(raw));
    } catch (_) {
      return StillnessData();
    }
  }

  /// Returns false if the platform refused to persist (mirrors the web app's
  /// "This browser can't save" warning).
  static Future<bool> save(StillnessData d) async {
    try {
      final sp = await SharedPreferences.getInstance();
      return await sp.setString(kStorageKey, jsonEncode(d.toJson()));
    } catch (_) {
      return false;
    }
  }

  /// Pretty-printed backup text — identical shape to the web "Copy backup".
  static String backupText(StillnessData d) =>
      const JsonEncoder.withIndent(' ').convert(d.toJson());

  /// Parse + validate a pasted backup. Throws [FormatException] if it is not a
  /// Stillness backup (no `tasks` array), exactly like the web restore.
  static StillnessData parseBackup(String text) {
    final decoded = jsonDecode(text);
    if (decoded is! Map || decoded['tasks'] is! List) {
      throw const FormatException('not-a-stillness-backup');
    }
    return StillnessData.clean(decoded);
  }
}
