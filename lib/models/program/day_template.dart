class DayTemplate {
  final int? id;
  final int programId;
  final String dayOfWeek; // e.g., 'Monday'
  final String routineName; // e.g., 'Push Day'

  DayTemplate({
    this.id,
    required this.programId,
    required this.dayOfWeek,
    required this.routineName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'programId': programId,
      'dayOfWeek': dayOfWeek,
      'routineName': routineName,
    };
  }

  factory DayTemplate.fromMap(Map<String, dynamic> map) {
    return DayTemplate(
      id: map['id'],
      programId: map['programId'],
      dayOfWeek: map['dayOfWeek'],
      routineName: map['routineName'],
    );
  }
}
