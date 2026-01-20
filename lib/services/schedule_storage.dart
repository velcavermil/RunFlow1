import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/schedule_model.dart';

class ScheduleStorage {
  static const String _key = 'schedule_runs';

  static Future<void> saveSchedule(ScheduleModel schedule) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];

    data.add(jsonEncode(schedule.toMap()));
    await prefs.setStringList(_key, data);
  }

  static Future<void> deleteSchedule(ScheduleModel schedule) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];

    data.removeWhere((e) {
      final s = ScheduleModel.fromMap(jsonDecode(e));
      return s.date == schedule.date;
    });

    await prefs.setStringList(_key, data);
  }


  static Future<List<ScheduleModel>> getSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];

    return data
        .map((e) => ScheduleModel.fromMap(jsonDecode(e)))
        .toList();
  }
}
