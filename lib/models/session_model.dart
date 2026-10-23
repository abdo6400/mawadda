class SessionModel {
  final String id;
  final String title;
  final List<String> categoryIds;
  final int? level; // null means all levels
  final List<String> questionIds;
  int currentIndex;
  final DateTime startedAt;
  bool isCompleted;

  SessionModel({
    required this.id,
    required this.title,
    required this.categoryIds,
    this.level,
    required this.questionIds,
    this.currentIndex = 0,
    required this.startedAt,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'categoryIds': categoryIds,
      'level': level,
      'questionIds': questionIds,
      'currentIndex': currentIndex,
      'startedAt': startedAt.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      categoryIds: (json['categoryIds'] as List<dynamic>).map((e) => e.toString()).toList(),
      level: json['level'] as int?,
      questionIds: (json['questionIds'] as List<dynamic>).map((e) => e.toString()).toList(),
      currentIndex: json['currentIndex'] as int? ?? 0,
      startedAt: DateTime.parse(json['startedAt'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  double get progressPercentage {
    if (questionIds.isEmpty) return 0.0;
    return (currentIndex + 1) / questionIds.length;
  }
}
