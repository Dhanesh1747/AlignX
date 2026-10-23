class Goal {
  final String id;
  final String title;
  final String category;
  final String type;
  final int targetCount;
  final int progressCount;

  const Goal({
    required this.id,
    required this.title,
    required this.category,
    required this.type,
    required this.targetCount,
    required this.progressCount,
  });

  bool get isComplete => progressCount >= targetCount;

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        category: json['category']?.toString() ?? 'HEALTH',
        type: json['type']?.toString() ?? 'DAILY',
        targetCount: (json['targetCount'] as num?)?.toInt() ?? 1,
        progressCount: (json['progressCount'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'category': category,
        'type': type,
        'targetCount': targetCount,
      };
}
