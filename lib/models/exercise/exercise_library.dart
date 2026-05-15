class ExerciseLibrary {
  final String id;
  final String name;
  final String cat;
  final String equip;
  final String type;
  final bool isCustom;

  ExerciseLibrary({
    required this.id,
    required this.name,
    required this.cat,
    required this.equip,
    required this.type,
    this.isCustom = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cat': cat,
      'equip': equip,
      'type': type,
      'isCustom': isCustom ? 1 : 0,
    };
  }

  factory ExerciseLibrary.fromMap(Map<String, dynamic> map) {
    return ExerciseLibrary(
      id: map['id'] as String,
      name: map['name'] as String,
      cat: map['cat'] as String,
      equip: map['equip'] as String,
      type: map['type'] as String,
      isCustom: map['isCustom'] == 1,
    );
  }

  factory ExerciseLibrary.fromJson(Map<String, dynamic> json) {
    return ExerciseLibrary(
      id: json['id'] as String,
      name: json['name'] as String,
      cat: json['cat'] as String,
      equip: json['equip'] as String,
      type: json['type'] as String,
      isCustom: false,
    );
  }
}
