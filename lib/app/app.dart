import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../core/services/question_service.dart';
import '../core/services/storage_service.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class MawaddaApp extends StatefulWidget {
  final StorageService storageService;
  final QuestionService questionService;

  const MawaddaApp({
    Key? key,
    required this.storageService,
    required this.questionService,
  }) : super(key: key);

  @override
  State<MawaddaApp> createState() => _MawaddaAppState();
}

class _MawaddaAppState extends State<MawaddaApp> {
  late String _themeMode;
  late final _router = createRouter(
    widget.storageService,
    widget.questionService,
    _handleThemeChanged,
  );

  @override
  void initState() {
    super.initState();
    _themeMode = widget.storageService.getThemeMode();
  }

  void _handleThemeChanged(String mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  ThemeMode _resolveThemeMode() {
    switch (_themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'مودة',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _resolveThemeMode(),
      routerConfig: _router,
    );
  }
}
