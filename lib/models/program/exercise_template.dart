class ExerciseTemplate {
  final int? id;
  final int dayTemplateId;
  final String exerciseName;
  final int targetSets;
  final int targetReps;

  ExerciseTemplate({
    this.id,
    required this.dayTemplateId,
    required this.exerciseName,
    required this.targetSets,
    required this.targetReps,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dayTemplateId': dayTemplateId,
      'exerciseName': exerciseName,
      'targetSets': targetSets,
      'targetReps': targetReps,
    };
  }

  factory ExerciseTemplate.fromMap(Map<String, dynamic> map) {
    return ExerciseTemplate(
      id: map['id'],
      dayTemplateId: map['dayTemplateId'],
      exerciseName: map['exerciseName'],
      targetSets: map['targetSets'],
      targetReps: map['targetReps'],
    );
  }
}
