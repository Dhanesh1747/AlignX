class Habit {
  final String id;
  final String userId;
  final String title;
  final String category;
  int currentStreak;
  bool completedToday;

  Habit({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    this.currentStreak = 0,
    this.completedToday = false,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      completedToday: json['completedToday'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'category': category,
      'currentStreak': currentStreak,
      'completedToday': completedToday,
    };
  }

  Habit copyWith({
    String? id,
    String? userId,
    String? title,
    String? category,
    int? currentStreak,
    bool? completedToday,
  }) {
    return Habit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      category: category ?? this.category,
      currentStreak: currentStreak ?? this.currentStreak,
      completedToday: completedToday ?? this.completedToday,
    );
  }
}
