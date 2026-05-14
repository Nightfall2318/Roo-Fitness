class ExerciseLibrary {
  final int? id;
  final String name;
  final String category; // e.g., 'Chest', 'Legs'
  final bool isCustom;

  ExerciseLibrary({
    this.id,
    required this.name,
    required this.category,
    this.isCustom = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'isCustom': isCustom ? 1 : 0,
    };
  }

  factory ExerciseLibrary.fromMap(Map<String, dynamic> map) {
    return ExerciseLibrary(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      isCustom: map['isCustom'] == 1,
    );
  }
}
