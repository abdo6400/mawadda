import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/services/question_service.dart';
import 'core/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = await StorageService.init();
  final questionService = QuestionService();
  await questionService.loadQuestions();

  runApp(
    MawaddaApp(
      storageService: storageService,
      questionService: questionService,
    ),
  );
}
