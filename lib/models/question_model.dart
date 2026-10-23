class QuestionModel {
  final String id;
  final String categoryId;
  final int level;
  final String question;
  final String followUp;
  final List<String> tags;

  const QuestionModel({
    required this.id,
    required this.categoryId,
    required this.level,
    required this.question,
    required this.followUp,
    required this.tags,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      level: json['level'] as int,
      question: json['question'] as String,
      followUp: json['followUp'] as String,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'level': level,
      'question': question,
      'followUp': followUp,
      'tags': tags,
    };
  }

  String get levelTitleArabic {
    switch (level) {
      case 1:
        return 'المستوى الأول: التعارف الأولي';
      case 2:
        return 'المستوى الثاني: فهم أعمق';
      case 3:
        return 'المستوى الثالث: مواقف وقرارات';
      default:
        return 'المستوى $level';
    }
  }
}
