import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/question_service.dart';
import '../../core/services/storage_service.dart';
import '../../models/category_model.dart';

class HomeScreen extends StatefulWidget {
  final QuestionService questionService;
  final StorageService storageService;

  const HomeScreen({
    Key? key,
    required this.questionService,
    required this.storageService,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late bool _hideExplored;

  @override
  void initState() {
    super.initState();
    _hideExplored = widget.storageService.getHideAnswered();
  }

  void _showLevelPicker(CategoryModel category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final color = Color(int.parse(category.colorHex.replaceFirst('#', '0xFF')));

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.auto_stories_rounded, color: color, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        category.nameArabic,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'اختر مستوى عمق البطاقات الحوارية:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
              const SizedBox(height: 12),

              // Level 1
              _buildLevelButton(
                ctx,
                title: 'المستوى الأول: التعارف الأولي',
                subtitle: 'أسئلة مريحة وممهدة للنقاش (100 بطاقة)',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/game?categoryId=${category.id}&level=1');
                },
              ),
              const SizedBox(height: 8),

              // Level 2
              _buildLevelButton(
                ctx,
                title: 'المستوى الثاني: فهم أعمق',
                subtitle: 'القيم والتطلعات وطريقة التفكير (100 بطاقة)',
                color: AppColors.secondaryDark,
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/game?categoryId=${category.id}&level=2');
                },
              ),
              const SizedBox(height: 8),

              // Level 3
              _buildLevelButton(
                ctx,
                title: 'المستوى الثالث: مواقف وقرارات',
                subtitle: 'سيناريوهات واقعية وقرارات حاسمة (100 بطاقة)',
                color: Colors.redAccent,
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/game?categoryId=${category.id}&level=3');
                },
              ),
              const SizedBox(height: 12),

              // Entire category 300 cards
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/game?categoryId=${category.id}');
                },
                child: const Text('بدء المحور كاملاً (300 بطاقة بالتدرج)', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLevelButton(
    BuildContext ctx, {
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.black26 : const Color(0xFFF9F7F1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeSession = widget.storageService.getActiveSession();
    final favoritesCount = widget.storageService.getFavorites().length;
    final answeredCount = widget.storageService.getAnsweredQuestions().length;
    final totalQuestions = widget.questionService.questions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('مودة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            SizedBox(width: 6),
            Icon(Icons.favorite_rounded, color: AppColors.secondary, size: 18),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline_rounded),
            tooltip: 'المفضلة',
            onPressed: () => context.push('/favorites'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'الإعدادات',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome & Spiritual Quote Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [AppColors.surfaceDark, const Color(0xFF1B3D34)]
                      : [AppColors.primary.withOpacity(0.08), const Color(0xFFE9F4F0)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.secondary.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite_rounded, color: AppColors.secondary, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'سَكَنٌ وَمَوَدَّةٌ وَرَحْمَة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.secondaryLight : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '2,400 سؤال حواري أصيل عبر 8 محاور متكاملة تبني جسور التفاهم والسكينة قبل الزواج.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Progress summary bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الأسئلة المستكشفة: $answeredCount من $totalQuestions',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                      Text(
                        '${((answeredCount / (totalQuestions == 0 ? 1 : totalQuestions)) * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: totalQuestions == 0 ? 0 : answeredCount / totalQuestions,
                      minHeight: 6,
                      backgroundColor: isDark ? Colors.black26 : Colors.black12,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Hide explored toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.filter_alt_outlined, size: 18, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'إخفاء الأسئلة التي نوقشت سابقاً',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Switch.adaptive(
                    value: _hideExplored,
                    activeColor: AppColors.primary,
                    onChanged: (val) async {
                      await widget.storageService.setHideAnswered(val);
                      setState(() {
                        _hideExplored = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 4 INTERACTIVE GAME MODES LAUNCHPAD
            const Text(
              'أنماط اللعب والحوار التفاعلية',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.35,
              children: [
                // 1. Deck Draw
                _buildModeCard(
                  icon: Icons.style_rounded,
                  title: 'سحب الكروت',
                  subtitle: 'سحب ثلاثي الأبعاد وتقليب',
                  color: AppColors.primary,
                  onTap: () => context.push('/game?mode=deck'),
                  isDark: isDark,
                ),

                // 2. Couples Challenge
                _buildModeCard(
                  icon: Icons.people_alt_rounded,
                  title: 'تحدي الشريكين',
                  subtitle: 'تبادل الأدوار وتوقع الإجابة',
                  color: const Color(0xFF2A6F97),
                  onTap: () => context.push('/game?mode=couples'),
                  isDark: isDark,
                ),

                // 3. Lucky Wheel
                _buildModeCard(
                  icon: Icons.track_changes_rounded,
                  title: 'عجلة الحوار',
                  subtitle: 'تدوير عشوائي للمحاور',
                  color: AppColors.secondaryDark,
                  onTap: () => context.push('/game?mode=wheel'),
                  isDark: isDark,
                ),

                // 4. This or That
                _buildModeCard(
                  icon: Icons.bolt_rounded,
                  title: 'تحدي إما / أو',
                  subtitle: 'ثنائيات خاطفة لقياس التوافق',
                  color: const Color(0xFF8B5A2B),
                  onTap: () => context.push('/game?mode=rapid'),
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Resume Session if active
            if (activeSession != null && !activeSession.isCompleted) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.secondary.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: AppColors.secondary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('جلسة حوار جارية', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          Text(activeSession.title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onPressed: () => context.push('/session'),
                      child: const Text('متابعة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Section Header: 8 Categories
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'محاور الحوار (8 محاور · 300 بطاقة لكل محور)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => context.push('/categories'),
                  child: const Text('المزيد'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Categories List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.questionService.categories.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final category = widget.questionService.categories[index];
                final catQuestions = widget.questionService.getQuestionsByCategory(category.id);
                final answeredInCat = catQuestions
                    .where((q) => widget.storageService.getAnsweredQuestions().contains(q.id))
                    .length;
                final color = Color(int.parse(category.colorHex.replaceFirst('#', '0xFF')));

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _showLevelPicker(category),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Icon(Icons.auto_stories_rounded, color: color, size: 22),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.nameArabic,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  category.descriptionArabic,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$answeredInCat / ${catQuestions.length}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.grey),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 9, color: Colors.grey), maxLines: 1),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
