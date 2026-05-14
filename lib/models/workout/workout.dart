class Workout {
  final int? id;
  final String title;
  final String date;
  final int durationMinutes;
  final String type; // e.g., 'Chest', 'Legs', 'Full Body'

  Workout({
    this.id,
    required this.title,
    required this.date,
    required this.durationMinutes,
    required this.type,
  });

  // Convert a Workout into a Map. The keys must correspond to the names of the 
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'durationMinutes': durationMinutes,
      'type': type,
    };
  }

  // Extract a Workout object from a Map.
  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'],
      title: map['title'],
      date: map['date'],
      durationMinutes: map['durationMinutes'],
      type: map['type'],
    );
  }
}
