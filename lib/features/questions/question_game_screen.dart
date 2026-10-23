import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/question_service.dart';
import '../../core/services/storage_service.dart';
import '../../models/question_model.dart';
import '../../models/category_model.dart';

class QuestionGameScreen extends StatefulWidget {
  final QuestionService questionService;
  final StorageService storageService;
  final String? categoryId;
  final int? level;
  final List<String>? customQuestionIds;

  const QuestionGameScreen({
    Key? key,
    required this.questionService,
    required this.storageService,
    this.categoryId,
    this.level,
    this.customQuestionIds,
  }) : super(key: key);

  @override
  State<QuestionGameScreen> createState() => _QuestionGameScreenState();
}

class _QuestionGameScreenState extends State<QuestionGameScreen> {
  late List<QuestionModel> _questions;
  int _currentIndex = 0;
  bool _showFollowUp = false;
  late Set<String> _favorites;

  @override
  void initState() {
    super.initState();
    _favorites = widget.storageService.getFavorites();

    if (widget.customQuestionIds != null && widget.customQuestionIds!.isNotEmpty) {
      _questions = widget.questionService.getQuestionsByIds(widget.customQuestionIds!);
    } else if (widget.categoryId != null) {
      _questions = widget.questionService.getQuestionsByCategory(
        widget.categoryId!,
        level: widget.level,
      );
    } else {
      _questions = widget.questionService.questions;
    }

    if (_questions.isNotEmpty) {
      widget.storageService.markQuestionViewed(_questions[_currentIndex].id);
    }
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  void _toggleFavorite() async {
    if (_questions.isEmpty) return;
    _triggerHaptic();
    final qId = _questions[_currentIndex].id;
    await widget.storageService.toggleFavorite(qId);
    setState(() {
      _favorites = widget.storageService.getFavorites();
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      _triggerHaptic();
      setState(() {
        _currentIndex++;
        _showFollowUp = false;
      });
      widget.storageService.markQuestionViewed(_questions[_currentIndex].id);
    } else {
      _showCompletionDialog();
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      _triggerHaptic();
      setState(() {
        _currentIndex--;
        _showFollowUp = false;
      });
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('أحسنتما!', textAlign: TextAlign.center),
          content: const Text(
            'لقد أتممتما استكشاف هذه المجموعة من الأسئلة الحوارية الهادفة. نسأل الله أن يبارك في مسعاكما ويوفقكما للخير.',
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.5),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('العودة للرئيسية'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('جلسة الحوار')),
        body: const Center(
          child: Text('لا توجد أسئلة متوفرة في هذا الاختيار حالياً.'),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentQ = _questions[_currentIndex];
    final category = widget.questionService.getCategoryById(currentQ.categoryId);
    final isFav = _favorites.contains(currentQ.id);

    final catColor = category != null
        ? Color(int.parse(category.colorHex.replaceFirst('#', '0xFF')))
        : AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(category?.nameArabic ?? 'بطاقات الحوار'),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
              color: isFav ? AppColors.favorite : null,
            ),
            tooltip: 'المفضلة',
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            children: [
              // Top Progress bar & Level indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      currentQ.levelTitleArabic,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: catColor,
                      ),
                    ),
                  ),
                  Text(
                    '${_currentIndex + 1} من ${_questions.length}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / _questions.length,
                  minHeight: 4,
                  backgroundColor: isDark ? Colors.black26 : Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(catColor),
                ),
              ),
              const SizedBox(height: 24),

              // Large Animated Question Card
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28.0),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: catColor.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Category badge icon
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: catColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.auto_stories_rounded, color: catColor, size: 28),
                          ),
                          const SizedBox(height: 20),

                          // Main Question Text
                          Text(
                            currentQ.question,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.6,
                              color: isDark ? AppColors.textDark : AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Follow-up question reveal section
                          if (currentQ.followUp.isNotEmpty) ...[
                            AnimatedCrossFade(
                              duration: const Duration(milliseconds: 300),
                              crossFadeState: _showFollowUp
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              firstChild: OutlinedButton.icon(
                                onPressed: () {
                                  _triggerHaptic();
                                  setState(() {
                                    _showFollowUp = true;
                                  });
                                },
                                icon: const Icon(Icons.help_outline_rounded, size: 18),
                                label: const Text(AppStrings.showFollowUp),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: catColor,
                                  side: BorderSide(color: catColor.withOpacity(0.4)),
                                ),
                              ),
                              secondChild: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.black26 : const Color(0xFFF7F5EE),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.secondary.withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.lightbulb_outline_rounded,
                                            size: 18, color: AppColors.secondary),
                                        SizedBox(width: 6),
                                        Text(
                                          'محور للمناقشة وتوسيع الفهم:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      currentQ.followUp,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 15,
                                        height: 1.5,
                                        color: isDark ? AppColors.textDark : AppColors.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // Tags
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            alignment: WrapAlignment.center,
                            children: currentQ.tags.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Bottom Navigation Controls (Previous, Skip, Next)
              Row(
                children: [
                  // Previous button
                  IconButton.filledTonal(
                    onPressed: _currentIndex > 0 ? _previousQuestion : null,
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: AppStrings.previous,
                  ),
                  const SizedBox(width: 8),

                  // Skip button
                  TextButton(
                    onPressed: _nextQuestion,
                    child: const Text(
                      AppStrings.skip,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const Spacer(),

                  // Next / Finish button
                  ElevatedButton(
                    onPressed: _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: catColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentIndex == _questions.length - 1 ? AppStrings.finish : AppStrings.next,
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
