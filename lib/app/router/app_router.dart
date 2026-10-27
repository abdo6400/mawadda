import 'package:go_router/go_router.dart';
import '../../core/services/question_service.dart';
import '../../core/services/storage_service.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/categories/categories_screen.dart';
import '../../features/questions/question_game_screen.dart';
import '../../features/sessions/session_screen.dart';
import '../../features/favorites/favorites_screen.dart';
import '../../features/settings/settings_screen.dart';

GoRouter createRouter(
  StorageService storageService,
  QuestionService questionService,
  void Function(String) onThemeChanged,
) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => SplashScreen(storageService: storageService),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => OnboardingScreen(storageService: storageService),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => HomeScreen(
          questionService: questionService,
          storageService: storageService,
        ),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => CategoriesScreen(
          questionService: questionService,
          storageService: storageService,
        ),
      ),
      GoRoute(
        path: '/game',
        builder: (context, state) {
          final categoryId = state.uri.queryParameters['categoryId'];
          final levelStr = state.uri.queryParameters['level'];
          final level = levelStr != null ? int.tryParse(levelStr) : null;
          final customQuestionIds = state.extra as List<String>?;

          final initialMode = state.uri.queryParameters['mode'];

          return QuestionGameScreen(
            questionService: questionService,
            storageService: storageService,
            categoryId: categoryId,
            level: level,
            customQuestionIds: customQuestionIds,
            initialMode: initialMode,
          );
        },
      ),
      GoRoute(
        path: '/session',
        builder: (context, state) => SessionScreen(
          questionService: questionService,
          storageService: storageService,
        ),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => FavoritesScreen(
          questionService: questionService,
          storageService: storageService,
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => SettingsScreen(
          storageService: storageService,
          onThemeChanged: onThemeChanged,
        ),
      ),
    ],
  );
}
