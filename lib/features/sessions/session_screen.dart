import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/question_service.dart';
import '../../core/services/storage_service.dart';
import '../../models/session_model.dart';
import '../../models/question_model.dart';

class SessionScreen extends StatefulWidget {
  final QuestionService questionService;
  final StorageService storageService;

  const SessionScreen({
    Key? key,
    required this.questionService,
    required this.storageService,
  }) : super(key: key);

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final Set<String> _selectedCategories = {};
  int? _selectedLevel; // null = all levels
  int _questionCount = 15;
  SessionModel? _activeSession;

  @override
  void initState() {
    super.initState();
    _activeSession = widget.storageService.getActiveSession();
    // Default select all categories
    for (var cat in widget.questionService.categories) {
      _selectedCategories.add(cat.id);
    }
  }

  void _startSession() {
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار محور واحد على الأقل')),
      );
      return;
    }

    // Filter candidate questions
    List<QuestionModel> pool = [];
    for (var catId in _selectedCategories) {
      final list = widget.questionService.getQuestionsByCategory(catId, level: _selectedLevel);
      pool.addAll(list);
    }

    pool.shuffle();
    final chosen = pool.take(_questionCount).map((q) => q.id).toList();

    if (chosen.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد أسئلة كافية في هذا الاختيار')),
      );
      return;
    }

    final newSession = SessionModel(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      title: _selectedLevel == null
          ? 'جلسة حوار شاملة (${chosen.length} سؤال)'
          : 'جلسة المستوى $_selectedLevel (${chosen.length} سؤال)',
      categoryIds: _selectedCategories.toList(),
      level: _selectedLevel,
      questionIds: chosen,
      currentIndex: 0,
      startedAt: DateTime.now(),
    );

    widget.storageService.saveActiveSession(newSession);

    // Launch game with this custom session
    context.push(
      '/game?session=custom',
      extra: chosen,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('جلسة حوار مخصصة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تخصيص جلسة الحوار',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'حدد المحاور التي تفضلان مناقشتها اليوم، ومستوى عمق الأسئلة وعددها لتناسب وقتكما.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Categories Selector
            const Text(
              'المحاور المراد تضمينها:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.questionService.categories.map((cat) {
                final isSelected = _selectedCategories.contains(cat.id);
                final color = Color(int.parse(cat.colorHex.replaceFirst('#', '0xFF')));

                return FilterChip(
                  label: Text(cat.nameArabic),
                  selected: isSelected,
                  selectedColor: color.withOpacity(0.2),
                  checkmarkColor: color,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(cat.id);
                      } else {
                        if (_selectedCategories.length > 1) {
                          _selectedCategories.remove(cat.id);
                        }
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Level Selector
            const Text(
              'مستوى عمق الأسئلة:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                _buildLevelRadio(null, 'جميع المستويات'),
                const SizedBox(width: 8),
                _buildLevelRadio(1, 'مستوى 1'),
                const SizedBox(width: 8),
                _buildLevelRadio(2, 'مستوى 2'),
                const SizedBox(width: 8),
                _buildLevelRadio(3, 'مستوى 3'),
              ],
            ),
            const SizedBox(height: 24),

            // Question Count
            const Text(
              'عدد بطاقات الجلسة:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Row(
              children: [10, 15, 20, 30].map((count) {
                final isSelected = _questionCount == count;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isSelected ? AppColors.primary : Colors.transparent,
                        foregroundColor: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        setState(() {
                          _questionCount = count;
                        });
                      },
                      child: Text(
                        '$count بطاقة',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 36),

            // Start Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startSession,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded),
                    SizedBox(width: 8),
                    Text('بدء الجلسة الآن', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelRadio(int? level, String label) {
    final isSelected = _selectedLevel == level;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedLevel = level;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.secondary.withOpacity(0.2) : Colors.transparent,
            border: Border.all(
              color: isSelected ? AppColors.secondary : Colors.grey.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.secondary : null,
            ),
          ),
        ),
      ),
    );
  }
}
