class Program {
  final int? id;
  final String name;
  final int durationWeeks;
  final String? startDate;

  Program({
    this.id,
    required this.name,
    required this.durationWeeks,
    this.startDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'durationWeeks': durationWeeks,
      'startDate': startDate,
    };
  }

  factory Program.fromMap(Map<String, dynamic> map) {
    return Program(
      id: map['id'],
      name: map['name'],
      durationWeeks: map['durationWeeks'],
      startDate: map['startDate'],
    );
  }
}
