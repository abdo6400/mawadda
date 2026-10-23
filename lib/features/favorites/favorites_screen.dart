import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/question_service.dart';
import '../../core/services/storage_service.dart';
import '../../models/question_model.dart';

class FavoritesScreen extends StatefulWidget {
  final QuestionService questionService;
  final StorageService storageService;

  const FavoritesScreen({
    Key? key,
    required this.questionService,
    required this.storageService,
  }) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Set<String> _favIds;
  String? _selectedCategoryFilter;

  @override
  void initState() {
    super.initState();
    _favIds = widget.storageService.getFavorites();
  }

  void _removeFavorite(String questionId) async {
    await widget.storageService.toggleFavorite(questionId);
    setState(() {
      _favIds = widget.storageService.getFavorites();
    });
  }

  void _startFavoritesSession(List<QuestionModel> favQuestions) {
    if (favQuestions.isEmpty) return;
    context.push(
      '/game?session=favorites',
      extra: favQuestions.map((q) => q.id).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allFavQuestions = widget.questionService.getQuestionsByIds(_favIds.toList());

    final filteredQuestions = _selectedCategoryFilter == null
        ? allFavQuestions
        : allFavQuestions.where((q) => q.categoryId == _selectedCategoryFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الأسئلة المفضلة'),
      ),
      body: allFavQuestions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bookmark_border_rounded, size: 48, color: AppColors.secondary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد أسئلة محفوظة في المفضلة',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'يمكنك حفظ أي بطاقة أثناء الحوار للرجوع إليها لاحقاً.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Top filter bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('الكل'),
                        selected: _selectedCategoryFilter == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategoryFilter = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ...widget.questionService.categories.map((cat) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: FilterChip(
                            label: Text(cat.nameArabic),
                            selected: _selectedCategoryFilter == cat.id,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategoryFilter = selected ? cat.id : null;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // Start session with favorites button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _startFavoritesSession(filteredQuestions),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text('بدء جلسة حوار بالأسئلة المفضلة (${filteredQuestions.length})'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Favorites list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredQuestions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final q = filteredQuestions[index];
                      final cat = widget.questionService.getCategoryById(q.categoryId);

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      cat?.nameArabic ?? '',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    q.levelTitleArabic,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.bookmark_remove_rounded, color: AppColors.favorite, size: 20),
                                    tooltip: 'إزالة',
                                    onPressed: () => _removeFavorite(q.id),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                q.question,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.5),
                              ),
                              if (q.followUp.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  '• ${q.followUp}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
