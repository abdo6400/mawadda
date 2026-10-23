import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawadda/models/question_model.dart';
import 'package:mawadda/models/category_model.dart';

void main() {
  group('Mawadda Question Dataset Verification', () {
    late Map<String, dynamic> data;
    late List<CategoryModel> categories;
    late List<QuestionModel> questions;

    setUpAll(() {
      final file = File('assets/questions/questions.json');
      expect(file.existsSync(), isTrue, reason: 'assets/questions/questions.json must exist');

      final content = file.readAsStringSync();
      data = jsonDecode(content) as Map<String, dynamic>;

      final rawCategories = data['categories'] as List<dynamic>;
      categories = rawCategories.map((c) => CategoryModel.fromJson(c as Map<String, dynamic>)).toList();

      final rawQuestions = data['questions'] as List<dynamic>;
      questions = rawQuestions.map((q) => QuestionModel.fromJson(q as Map<String, dynamic>)).toList();
    });

    test('Should contain exactly 6 categories', () {
      expect(categories.length, equals(6));
      final expectedCategoryIds = {
        'religion_values',
        'personality_thinking',
        'family_relationships',
        'responsibilities_life',
        'finance_work',
        'children_future',
      };
      final foundIds = categories.map((c) => c.id).toSet();
      expect(foundIds, equals(expectedCategoryIds));
    });

    test('Should contain exactly 900 questions', () {
      expect(questions.length, equals(900));
    });

    test('All question IDs must be unique', () {
      final ids = <String>{};
      for (final q in questions) {
        expect(ids.contains(q.id), isFalse, reason: 'Duplicate question ID found: ${q.id}');
        ids.add(q.id);
      }
      expect(ids.length, equals(900));
    });

    test('Each category must have exactly 150 questions (50 L1, 50 L2, 50 L3)', () {
      for (final cat in categories) {
        final catQuestions = questions.where((q) => q.categoryId == cat.id).toList();
        expect(catQuestions.length, equals(150), reason: 'Category ${cat.id} does not have 150 questions');

        final l1 = catQuestions.where((q) => q.level == 1).toList();
        final l2 = catQuestions.where((q) => q.level == 2).toList();
        final l3 = catQuestions.where((q) => q.level == 3).toList();

        expect(l1.length, equals(50), reason: 'Category ${cat.id} level 1 count is not 50');
        expect(l2.length, equals(50), reason: 'Category ${cat.id} level 2 count is not 50');
        expect(l3.length, equals(50), reason: 'Category ${cat.id} level 3 count is not 50');
      }
    });

    test('All questions must have valid Arabic text and follow-up prompts', () {
      for (final q in questions) {
        expect(q.question.trim().length, greaterThan(10), reason: 'Question ${q.id} is too short');
        expect(q.followUp.trim().length, greaterThan(10), reason: 'Follow-up for ${q.id} is too short');
        expect(q.tags.isNotEmpty, isTrue, reason: 'Tags for ${q.id} must not be empty');
      }
    });
  });
}
