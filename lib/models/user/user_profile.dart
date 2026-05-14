class UserProfile {
  final int? id;
  final String name;
  final double weight;
  final double height;
  final String goal;

  UserProfile({
    this.id,
    required this.name,
    required this.weight,
    required this.height,
    required this.goal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'weight': weight,
      'height': height,
      'goal': goal,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      name: map['name'],
      weight: map['weight'],
      height: map['height'],
      goal: map['goal'],
    );
  }
}
