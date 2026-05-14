class ActiveProgram {
  final int? id;
  final int templateId;
  final String startDate;
  final int currentWeek;
  final bool isCompleted;

  ActiveProgram({
    this.id,
    required this.templateId,
    required this.startDate,
    this.currentWeek = 1,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'templateId': templateId,
      'startDate': startDate,
      'currentWeek': currentWeek,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory ActiveProgram.fromMap(Map<String, dynamic> map) {
    return ActiveProgram(
      id: map['id'],
      templateId: map['templateId'],
      startDate: map['startDate'],
      currentWeek: map['currentWeek'],
      isCompleted: map['isCompleted'] == 1,
    );
  }
}
