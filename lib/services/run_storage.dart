import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/run_model.dart';

class RunStorage {
  static const String _key = 'runs';

  // ================= SAVE RUN =================
  static Future<void> saveRun(RunModel run) async {
    final prefs = await SharedPreferences.getInstance();

    final List<String> existing =
        prefs.getStringList(_key) ?? [];

    existing.add(jsonEncode(run.toMap()));

    await prefs.setStringList(_key, existing);
  }

  // ================= GET ALL RUNS =================
  static Future<List<RunModel>> getRuns() async {
    final prefs = await SharedPreferences.getInstance();

    final List<String> data =
        prefs.getStringList(_key) ?? [];

    return data
        .map((e) => RunModel.fromMap(jsonDecode(e)))
        .toList();
  }

  // ================= CLEAR (OPSIONAL) =================
  static Future<void> clearRuns() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
