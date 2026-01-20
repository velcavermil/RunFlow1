class ScheduleModel {
  final DateTime date;
  final String runType;
  final double distance;

  ScheduleModel({
    required this.date,
    required this.runType,
    required this.distance,
  });

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'runType': runType,
        'distance': distance,
      };

  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      date: DateTime.parse(map['date']),
      runType: map['runType'],
      distance: (map['distance'] as num).toDouble(),
    );
  }
}
