import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/category_model.dart';
import '../../models/question_model.dart';

class QuestionService {
  List<CategoryModel> _categories = [];
  List<QuestionModel> _questions = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<CategoryModel> get categories => List.unmodifiable(_categories);
  List<QuestionModel> get questions => List.unmodifiable(_questions);

  Future<void> loadQuestions() async {
    if (_isLoaded) return;
    try {
      final jsonString = await rootBundle.loadString('assets/questions/questions.json');
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      final rawCategories = data['categories'] as List<dynamic>;
      _categories = rawCategories.map((c) => CategoryModel.fromJson(c as Map<String, dynamic>)).toList();

      final rawQuestions = data['questions'] as List<dynamic>;
      _questions = rawQuestions.map((q) => QuestionModel.fromJson(q as Map<String, dynamic>)).toList();

      _isLoaded = true;
    } catch (e) {
      // Fallback if needed
      rethrow;
    }
  }

  // Load from raw json directly (useful for testing or fallback)
  void loadFromRaw(Map<String, dynamic> data) {
    final rawCategories = data['categories'] as List<dynamic>;
    _categories = rawCategories.map((c) => CategoryModel.fromJson(c as Map<String, dynamic>)).toList();

    final rawQuestions = data['questions'] as List<dynamic>;
    _questions = rawQuestions.map((q) => QuestionModel.fromJson(q as Map<String, dynamic>)).toList();
    _isLoaded = true;
  }

  QuestionModel? getQuestionById(String id) {
    try {
      return _questions.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  CategoryModel? getCategoryById(String categoryId) {
    try {
      return _categories.firstWhere((c) => c.id == categoryId);
    } catch (_) {
      return null;
    }
  }

  List<QuestionModel> getQuestionsByCategory(String categoryId, {int? level}) {
    return _questions.where((q) {
      if (q.categoryId != categoryId) return false;
      if (level != null && q.level != level) return false;
      return true;
    }).toList();
  }

  List<QuestionModel> getQuestionsByIds(List<String> ids) {
    final map = {for (var q in _questions) q.id: q};
    final List<QuestionModel> result = [];
    for (var id in ids) {
      if (map.containsKey(id)) {
        result.add(map[id]!);
      }
    }
    return result;
  }

  List<QuestionModel> getUnviewedQuestions(Set<String> viewedIds, {String? categoryId, int? level}) {
    return _questions.where((q) {
      if (viewedIds.contains(q.id)) return false;
      if (categoryId != null && q.categoryId != categoryId) return false;
      if (level != null && q.level != level) return false;
      return true;
    }).toList();
  }
}
