import 'package:flutter_test/flutter_test.dart';
import 'package:mawadda/models/session_model.dart';
import 'package:mawadda/models/question_model.dart';

void main() {
  group('SessionModel and QuestionModel unit tests', () {
    test('SessionModel serialization and progress calculation', () {
      final session = SessionModel(
        id: 'session_test_001',
        title: 'جلسة تجريبية',
        categoryIds: ['religion_values', 'finance_work'],
        level: 1,
        questionIds: ['rel_1_01', 'rel_1_02', 'fin_1_01', 'fin_1_02'],
        currentIndex: 1,
        startedAt: DateTime(2026, 1, 1),
      );

      expect(session.progressPercentage, equals(0.5)); // (1 + 1) / 4 = 2 / 4 = 0.5
      expect(session.isCompleted, isFalse);

      final json = session.toJson();
      final restored = SessionModel.fromJson(json);

      expect(restored.id, equals(session.id));
      expect(restored.title, equals(session.title));
      expect(restored.currentIndex, equals(1));
      expect(restored.categoryIds.length, equals(2));
      expect(restored.questionIds.length, equals(4));
    });

    test('QuestionModel levelTitleArabic formatting', () {
      const q1 = QuestionModel(
        id: 'q1',
        categoryId: 'cat1',
        level: 1,
        question: 'سؤال 1',
        followUp: 'فرعي 1',
        tags: ['tag1'],
      );
      const q2 = QuestionModel(
        id: 'q2',
        categoryId: 'cat1',
        level: 2,
        question: 'سؤال 2',
        followUp: 'فرعي 2',
        tags: ['tag2'],
      );
      const q3 = QuestionModel(
        id: 'q3',
        categoryId: 'cat1',
        level: 3,
        question: 'سؤال 3',
        followUp: 'فرعي 3',
        tags: ['tag3'],
      );

      expect(q1.levelTitleArabic, contains('التعارف الأولي'));
      expect(q2.levelTitleArabic, contains('فهم أعمق'));
      expect(q3.levelTitleArabic, contains('مواقف وقرارات'));
    });
  });
}
