class RunModel {
  /// Jarak dalam kilometer
  final double distance;

  /// Durasi dalam detik
  final int duration;

  /// Tanggal & waktu lari
  final DateTime date;

  RunModel({
    required this.distance,
    required this.duration,
    required this.date,
  });

  /// Convert object → Map (untuk storage)
  Map<String, dynamic> toMap() {
    return {
      'distance': distance,
      'duration': duration,
      'date': date.toIso8601String(),
    };
  }

  /// Convert Map → object
  factory RunModel.fromMap(Map<String, dynamic> map) {
    return RunModel(
      distance: (map['distance'] as num).toDouble(),
      duration: map['duration'] as int,
      date: DateTime.parse(map['date']),
    );
  }

  /// Pace (menit / km)
  double get pace {
    if (distance == 0) return 0;
    return (duration / 60) / distance;
  }

  /// Durasi format mm:ss
  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
