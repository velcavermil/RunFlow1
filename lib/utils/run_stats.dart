import '../models/run_model.dart';

class RunStats {
  /// Ambil data lari bulan ini
  static List<RunModel> thisMonth(List<RunModel> runs) {
    final now = DateTime.now();
    return runs.where((r) =>
        r.date.month == now.month &&
        r.date.year == now.year).toList();
  }

  /// Total jarak (km)
  static double totalDistance(List<RunModel> runs) {
    return runs.fold(0.0, (sum, r) => sum + r.distance);
  }

  /// Jumlah sesi lari
  static int totalRuns(List<RunModel> runs) {
    return runs.length;
  }

  /// Pace rata-rata (menit/km)
  static double averagePace(List<RunModel> runs) {
    if (runs.isEmpty) return 0;
    final totalPace = runs.fold(0.0, (sum, r) => sum + r.pace);
    return totalPace / runs.length;
  }

  /// Durasi rata-rata
  static Duration averageDuration(List<RunModel> runs) {
    if (runs.isEmpty) return Duration.zero;
    final totalSeconds =
        runs.fold(0, (sum, r) => sum + r.duration);
    return Duration(seconds: totalSeconds ~/ runs.length);
  }
}
