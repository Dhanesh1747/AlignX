class Exercise {
  final String id;
  final String title;
  final String targetArea;
  final String duration;
  final String difficulty;
  final String instructions;
  final String benefits;

  Exercise({
    required this.id,
    required this.title,
    required this.targetArea,
    required this.duration,
    required this.difficulty,
    required this.instructions,
    required this.benefits,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      targetArea: json['targetArea']?.toString() ?? 'Posture Alignment',
      duration: json['duration']?.toString() ?? '1 min',
      difficulty: json['difficulty']?.toString() ?? 'Beginner',
      instructions: json['instructions']?.toString() ?? '',
      benefits: json['benefits']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'targetArea': targetArea,
      'duration': duration,
      'difficulty': difficulty,
      'instructions': instructions,
      'benefits': benefits,
    };
  }
}
