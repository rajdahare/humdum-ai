class ScheduleItem {
  final String id;
  final String title;
  final DateTime time;
  final String? details;

  ScheduleItem({
    required this.id,
    required this.title,
    required this.time,
    this.details,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'time': time.toIso8601String(),
        'details': details,
      };
}


