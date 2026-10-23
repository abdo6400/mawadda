import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/question_service.dart';
import '../../core/services/storage_service.dart';

class CategoriesScreen extends StatelessWidget {
  final QuestionService questionService;
  final StorageService storageService;

  const CategoriesScreen({
    Key? key,
    required this.questionService,
    required this.storageService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final answeredIds = storageService.getAnsweredQuestions();

    return Scaffold(
      appBar: AppBar(
        title: const Text('المحاور الحوارية'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20.0),
        itemCount: questionService.categories.length,
        itemBuilder: (context, index) {
          final cat = questionService.categories[index];
          final catQuestions = questionService.getQuestionsByCategory(cat.id);
          final answeredCount = catQuestions.where((q) => answeredIds.contains(q.id)).length;
          final color = Color(int.parse(cat.colorHex.replaceFirst('#', '0xFF')));

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.forum_rounded, color: color, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.nameArabic,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${catQuestions.length} سؤالاً موزعة على 3 مستويات',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    cat.descriptionArabic,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Progress
                  Row(
                    children: [
                      Text(
                        'المنجز: $answeredCount من ${catQuestions.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${((answeredCount / catQuestions.length) * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: catQuestions.isEmpty ? 0 : answeredCount / catQuestions.length,
                      minHeight: 5,
                      backgroundColor: isDark ? Colors.black26 : Colors.black12,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Action buttons: All levels or pick level
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            context.push('/game?categoryId=${cat.id}');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text('بدء المحور كاملاً'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _showLevelPicker(context, cat.id, cat.nameArabic),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          side: BorderSide(color: color.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        child: const Text('اختيار مستوى'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLevelPicker(BuildContext context, String categoryId, String catName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اختر المستوى - $catName',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text('1', style: TextStyle(color: Colors.white)),
                ),
                title: const Text('المستوى الأول: التعارف الأولي'),
                subtitle: const Text('أسئلة مريحة وممهدة للنقاش'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/game?categoryId=$categoryId&level=1');
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.secondary,
                  child: Text('2', style: TextStyle(color: Colors.black)),
                ),
                title: const Text('المستوى الثاني: فهم أعمق'),
                subtitle: const Text('تطلعات، مبادئ، وطريقة التفكير'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/game?categoryId=$categoryId&level=2');
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.deepOrange,
                  child: Text('3', style: TextStyle(color: Colors.white)),
                ),
                title: const Text('المستوى الثالث: مواقف وقرارات'),
                subtitle: const Text('سيناريوهات واقعية وقرارات مشتركة'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/game?categoryId=$categoryId&level=3');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
