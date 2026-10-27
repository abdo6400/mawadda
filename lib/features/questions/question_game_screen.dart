import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/question_service.dart';
import '../../core/services/storage_service.dart';
import '../../models/question_model.dart';
import '../../models/category_model.dart';
import '../../models/rapid_pair_model.dart';

class QuestionGameScreen extends StatefulWidget {
  final QuestionService questionService;
  final StorageService storageService;
  final String? categoryId;
  final int? level;
  final List<String>? customQuestionIds;
  final String? initialMode; // 'deck', 'couples', 'wheel', 'rapid'

  const QuestionGameScreen({
    Key? key,
    required this.questionService,
    required this.storageService,
    this.categoryId,
    this.level,
    this.customQuestionIds,
    this.initialMode,
  }) : super(key: key);

  @override
  State<QuestionGameScreen> createState() => _QuestionGameScreenState();
}

class _QuestionGameScreenState extends State<QuestionGameScreen> with TickerProviderStateMixin {
  late List<QuestionModel> _questions;
  int _currentIndex = 0;
  late Set<String> _favorites;

  // Active Game Mode: 'deck', 'couples', 'wheel', 'rapid'
  late String _gameMode;

  // 3D Card Swipe state & animations
  double _dragOffset = 0.0;
  late AnimationController _swipeAnimController;
  late Animation<double> _swipeAnimation;

  // 3D Card Flip state & animation
  bool _isCardFlipped = false;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  // Mode 2: Couples Challenge State
  bool _couplesTurnGroom = true; // true = groom, false = bride
  int _couplesScore = 0;
  bool _showPartnerGuess = false;

  // Mode 3: Lucky Wheel State
  late AnimationController _wheelController;
  late Animation<double> _wheelAnimation;
  double _wheelRotation = 0.0;
  CategoryModel? _wheelLandedCategory;
  bool _wheelSpinning = false;

  // Mode 4: Rapid Dilemmas State
  int _rapidIndex = 0;
  final Map<int, String> _rapidGroomChoice = {};
  final Map<int, String> _rapidBrideChoice = {};

  @override
  void initState() {
    super.initState();
    _gameMode = widget.initialMode ?? 'deck';
    _favorites = widget.storageService.getFavorites();

    // Setup questions
    if (widget.customQuestionIds != null && widget.customQuestionIds!.isNotEmpty) {
      _questions = widget.questionService.getQuestionsByIds(widget.customQuestionIds!);
    } else if (widget.categoryId != null) {
      _questions = widget.questionService.getQuestionsByCategory(
        widget.categoryId!,
        level: widget.level,
      );
    } else {
      _questions = List.from(widget.questionService.questions)..shuffle();
    }

    if (_questions.isEmpty) {
      _questions = widget.questionService.questions;
    }

    if (_questions.isNotEmpty) {
      widget.storageService.markQuestionViewed(_questions[_currentIndex].id);
    }

    // Swipe animation
    _swipeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _swipeAnimation = Tween<double>(begin: 0, end: 0).animate(_swipeAnimController);

    // 3D Flip animation
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    // Lucky Wheel animation
    _wheelController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _wheelAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _wheelController, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() {});
      })..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _onWheelFinished();
        }
      });
  }

  @override
  void dispose() {
    _swipeAnimController.dispose();
    _flipController.dispose();
    _wheelController.dispose();
    super.dispose();
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

  void _flipCard() {
    _triggerHaptic();
    if (_isCardFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _isCardFlipped = !_isCardFlipped;
    });
  }

  void _resetCardFlip() {
    if (_isCardFlipped) {
      _flipController.reset();
      _isCardFlipped = false;
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      _triggerHaptic();
      _resetCardFlip();
      setState(() {
        _currentIndex++;
        _dragOffset = 0;
        _showPartnerGuess = false;
        _couplesTurnGroom = !_couplesTurnGroom;
      });
      widget.storageService.markQuestionViewed(_questions[_currentIndex].id);
    } else {
      _showCompletionDialog();
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      _triggerHaptic();
      _resetCardFlip();
      setState(() {
        _currentIndex--;
        _dragOffset = 0;
        _showPartnerGuess = false;
      });
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_dragOffset.abs() > 80 || velocity.abs() > 400) {
      // Swiped away
      final flyOutX = _dragOffset > 0 ? 400.0 : -400.0;
      _swipeAnimation = Tween<double>(begin: _dragOffset, end: flyOutX).animate(
        CurvedAnimation(parent: _swipeAnimController, curve: Curves.easeOut),
      );
      _swipeAnimController.forward(from: 0).then((_) {
        _nextQuestion();
        _dragOffset = 0;
      });
    } else {
      // Spring back to center
      _swipeAnimation = Tween<double>(begin: _dragOffset, end: 0.0).animate(
        CurvedAnimation(parent: _swipeAnimController, curve: Curves.easeOutBack),
      );
      _swipeAnimController.forward(from: 0).then((_) {
        setState(() {
          _dragOffset = 0;
        });
      });
    }
  }

  void _spinWheel() {
    if (_wheelSpinning) return;
    _triggerHaptic();
    setState(() {
      _wheelSpinning = true;
      _wheelLandedCategory = null;
    });

    final categories = widget.questionService.categories;
    if (categories.isEmpty) return;

    final rand = math.Random();
    // 5 to 8 full rotations + slice offset
    final targetIndex = rand.nextInt(categories.length);
    final sliceAngle = (2 * math.pi) / categories.length;
    final totalRotations = (5 + rand.nextInt(4)) * 2 * math.pi;
    final targetAngle = totalRotations + (targetIndex * sliceAngle) + (sliceAngle / 2);

    _wheelAnimation = Tween<double>(begin: _wheelRotation, end: _wheelRotation + targetAngle).animate(
      CurvedAnimation(parent: _wheelController, curve: Curves.easeOutCirc),
    );

    _wheelController.forward(from: 0);
  }

  void _onWheelFinished() {
    final categories = widget.questionService.categories;
    if (categories.isEmpty) return;

    final sliceAngle = (2 * math.pi) / categories.length;
    final normalized = _wheelAnimation.value % (2 * math.pi);
    // Find index corresponding to the pointer at top (3*pi/2 or 0)
    int index = ((2 * math.pi - normalized) / sliceAngle).floor() % categories.length;
    final landed = categories[index];

    setState(() {
      _wheelSpinning = false;
      _wheelRotation = _wheelAnimation.value % (2 * math.pi);
      _wheelLandedCategory = landed;
    });
    _triggerHaptic();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _triggerHaptic();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 18),
            SizedBox(width: 8),
            Text('تم نسخ السؤال بنجاح إلى الحافظة', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openNoteDialog(QuestionModel question) {
    final existingNote = widget.storageService.getNote(question.id) ?? '';
    final controller = TextEditingController(text: existingNote);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Container(
            padding: const EdgeInsets.all(22),
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
                    const Row(
                      children: [
                        Icon(Icons.edit_note_rounded, color: AppColors.secondary, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'ملاحظة خاصة على هذا السؤال',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  question.question,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'اكتب خواطرك وملاحظاتك الشخصية هنا (محفوظة محلياً فقط)...',
                    hintStyle: const TextStyle(fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          await widget.storageService.saveNote(question.id, controller.text);
                          _triggerHaptic();
                          if (mounted) Navigator.pop(ctx);
                          setState(() {});
                        },
                        child: const Text('حفظ الملاحظة', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    if (existingNote.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        tooltip: 'حذف الملاحظة',
                        onPressed: () async {
                          await widget.storageService.saveNote(question.id, '');
                          _triggerHaptic();
                          if (mounted) Navigator.pop(ctx);
                          setState(() {});
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          title: const Column(
            children: [
              Icon(Icons.auto_awesome_rounded, color: AppColors.secondary, size: 48),
              SizedBox(height: 12),
              Text(
                'أحسنتما! بارك الله في مسعاكما',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
              ),
            ],
          ),
          content: Text(
            'لقد أتممتما استكشاف هذه المجموعة من البطاقات الحوارية. نسأل الله أن يبارك في هذا الحوار الواعي ويجعله خطوة خير ومودة وسكينة نحو بيت مسلم مستقر.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.6, color: isDark ? AppColors.textDark : AppColors.textLight),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('العودة للرئيسية', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentQ = _questions.isNotEmpty ? _questions[_currentIndex] : null;
    final category = currentQ != null ? widget.questionService.getCategoryById(currentQ.categoryId) : null;
    final isFav = currentQ != null && _favorites.contains(currentQ.id);

    final catColor = category != null
        ? Color(int.parse(category.colorHex.replaceFirst('#', '0xFF')))
        : AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _gameMode == 'wheel'
              ? 'عجلة الحوار الدوارة'
              : _gameMode == 'rapid'
                  ? 'تحدي إما / أو الخاطف'
                  : (category?.nameArabic ?? 'بطاقات الحوار'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          if (currentQ != null && _gameMode != 'rapid') ...[
            IconButton(
              icon: Icon(
                isFav ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                color: isFav ? AppColors.favorite : null,
              ),
              tooltip: 'المفضلة',
              onPressed: _toggleFavorite,
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'نسخ السؤال',
              onPressed: () => _copyToClipboard(currentQ.question),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // TOP GAME MODE SWITCHER BAR
            _buildModeSwitcher(isDark),

            // BODY BY ACTIVE MODE
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
                child: _buildModeContent(currentQ, category, catColor, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Top Tabs: Deck Draw, Couples, Lucky Wheel, Rapid This-or-That
  Widget _buildModeSwitcher(bool isDark) {
    final modes = [
      {'id': 'deck', 'title': '🃏 سحب الكروت'},
      {'id': 'couples', 'title': '👥 تحدي الشريكين'},
      {'id': 'wheel', 'title': '🎡 عجلة الحوار'},
      {'id': 'rapid', 'title': '⚡ إما / أو'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.black38 : const Color(0xFFEEEBE3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: modes.map((m) {
          final isSelected = _gameMode == m['id'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                _triggerHaptic();
                setState(() {
                  _gameMode = m['id']!;
                  _resetCardFlip();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? (isDark ? AppColors.surfaceDark : Colors.white) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  m['title']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModeContent(
    QuestionModel? currentQ,
    CategoryModel? category,
    Color catColor,
    bool isDark,
  ) {
    if (_gameMode == 'wheel') {
      return _buildLuckyWheelView(isDark);
    }

    if (_gameMode == 'rapid') {
      return _buildRapidDilemmaView(isDark);
    }

    if (currentQ == null) {
      return const Center(child: Text('لا توجد بطاقات متاحة'));
    }

    // MODE 1 & 2: Interactive 3D Card Deck
    return Column(
      children: [
        // Progress header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: catColor.withOpacity(0.3)),
              ),
              child: Text(
                category?.nameArabic ?? 'محور الحوار',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: catColor),
              ),
            ),
            if (_gameMode == 'couples')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.secondary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'التوافق: $_couplesScore',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              '${_currentIndex + 1} من ${_questions.length}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Linear Progress
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions.length,
            minHeight: 4,
            backgroundColor: isDark ? Colors.black26 : Colors.black12,
            valueColor: AlwaysStoppedAnimation<Color>(catColor),
          ),
        ),
        const SizedBox(height: 12),

        // Couples turn prompt banner
        if (_gameMode == 'couples')
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _couplesTurnGroom
                  ? const Color(0xFF2A6F97).withOpacity(0.15)
                  : const Color(0xFFE91E63).withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _couplesTurnGroom ? const Color(0xFF2A6F97) : const Color(0xFFE91E63),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _couplesTurnGroom ? '👨 دور الخطيب للإجابة' : '🧕 دور الخطيبة للإجابة',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _couplesTurnGroom ? const Color(0xFF2A6F97) : const Color(0xFFE91E63),
                  ),
                ),
              ],
            ),
          ),

        // 3D STACKED INTERACTIVE CARD DECK
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 0.75,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Layer 3: Under card (Depth effect)
                  if (_currentIndex + 2 < _questions.length)
                    Transform.translate(
                      offset: const Offset(0, 20),
                      child: Transform.scale(
                        scale: 0.90,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark.withOpacity(0.5) : const Color(0xFFEDE8DD),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: catColor.withOpacity(0.15)),
                          ),
                        ),
                      ),
                    ),

                  // Layer 2: Middle card
                  if (_currentIndex + 1 < _questions.length)
                    Transform.translate(
                      offset: const Offset(0, 10),
                      child: Transform.scale(
                        scale: 0.95,
                        child: Transform.rotate(
                          angle: 0.03,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.cardDark : const Color(0xFFF5F2EB),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: catColor.withOpacity(0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.favorite_rounded,
                                size: 80,
                                color: catColor.withOpacity(0.06),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Layer 1: Active Interactive Top Card (Draggable + 3D Flip)
                  GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        _dragOffset += details.primaryDelta!;
                      });
                    },
                    onHorizontalDragEnd: _handleDragEnd,
                    onTap: _flipCard,
                    child: AnimatedBuilder(
                      animation: _swipeAnimController,
                      builder: (context, child) {
                        final currentOffset = _swipeAnimController.isAnimating
                            ? _swipeAnimation.value
                            : _dragOffset;
                        final rotationAngle = (currentOffset / 300) * 0.15;

                        return Transform.translate(
                          offset: Offset(currentOffset, 0),
                          child: Transform.rotate(
                            angle: rotationAngle,
                            child: child,
                          ),
                        );
                      },
                      child: AnimatedBuilder(
                        animation: _flipAnimation,
                        builder: (context, child) {
                          final angle = _flipAnimation.value * math.pi;
                          final isUnder = angle > (math.pi / 2);

                          return Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(angle),
                            alignment: Alignment.center,
                            child: isUnder
                                ? Transform(
                                    transform: Matrix4.identity()..rotateY(math.pi),
                                    alignment: Alignment.center,
                                    child: _buildBackFace(currentQ, category, catColor, isDark),
                                  )
                                : _buildFrontFace(currentQ, category, catColor, isDark),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Couples Mode "Guess Partner's Answer" Button
        if (_gameMode == 'couples') ...[
          const SizedBox(height: 10),
          if (!_showPartnerGuess)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondaryDark,
                side: const BorderSide(color: AppColors.secondary, style: BorderStyle.solid),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                _triggerHaptic();
                setState(() => _showPartnerGuess = true);
              },
              icon: const Icon(Icons.psychology_rounded, size: 18),
              label: const Text('خمن إجابة شريكك قبل ما يتكلم 💭', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.secondary.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Text('هل تطابقت التوقعات؟', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.emerald,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onPressed: () {
                      _triggerHaptic();
                      setState(() {
                        _couplesScore++;
                        _showPartnerGuess = false;
                      });
                    },
                    icon: const Icon(Icons.check_circle_rounded, size: 14),
                    label: const Text('نعم! (+1)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: () {
                      _triggerHaptic();
                      setState(() => _showPartnerGuess = false);
                    },
                    child: const Text('لا بأس', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ),
                ],
              ),
            ),
        ],

        const SizedBox(height: 12),

        // Bottom Controls Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Previous Card
            IconButton.filledTonal(
              onPressed: _currentIndex > 0 ? _previousQuestion : null,
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'البطاقة السابقة',
            ),

            // Flip Card Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
              onPressed: _flipCard,
              icon: Icon(_isCardFlipped ? Icons.flip_to_front_rounded : Icons.flip_to_back_rounded, size: 18),
              label: Text(
                _isCardFlipped ? 'وجه البطاقة' : 'السؤال الفرعي',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),

            // Next Card / Swipe
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: _nextQuestion,
              icon: const Icon(Icons.arrow_forward_rounded),
              tooltip: 'البطاقة التالية',
            ),
          ],
        ),
      ],
    );
  }

  // FRONT FACE OF 3D CARD
  Widget _buildFrontFace(QuestionModel currentQ, CategoryModel? category, Color catColor, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: catColor.withOpacity(0.55), width: 2),
        boxShadow: [
          BoxShadow(
            color: catColor.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.favorite_rounded, size: 12, color: catColor),
                    const SizedBox(width: 4),
                    Text(
                      currentQ.levelTitleArabic.split(':')[0],
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: catColor),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.touch_app_rounded, size: 11, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('وجه البطاقة', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),

          // Main Question text
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  currentQ.question,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.6,
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                  ),
                ),
              ),
            ),
          ),

          // Bottom Tags & Hint
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black38 : const Color(0xFFF9F7F1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
                child: const Text(
                  '👆 انقر في أي مكان لقلب البطاقة وكشف السؤال الفرعي',
                  style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.swipe_rounded, size: 12, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('اسحب للتالي', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  Wrap(
                    spacing: 4,
                    children: currentQ.tags.take(2).map((t) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#$t',
                          style: TextStyle(fontSize: 9, color: catColor, fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // BACK FACE OF 3D CARD
  Widget _buildBackFace(QuestionModel currentQ, CategoryModel? category, Color catColor, bool isDark) {
    final note = widget.storageService.getNote(currentQ.id);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.secondary.withOpacity(0.7), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top bar on back face
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 12, color: AppColors.secondaryDark),
                    SizedBox(width: 4),
                    Text(
                      'ظهر البطاقة: تعميق الحوار',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondaryDark),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, size: 20, color: AppColors.secondary),
                tooltip: 'إضافة ملاحظة شخصية',
                onPressed: () => _openNoteDialog(currentQ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Follow-up Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.help_outline_rounded, size: 14, color: AppColors.secondaryDark),
                    SizedBox(width: 6),
                    Text(
                      'السؤال الفرعي لتوسيع الحوار:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondaryDark),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  currentQ.followUp,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Coaching tip
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : const Color(0xFFF9F7F1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('💡 ', style: TextStyle(fontSize: 14)),
                Expanded(
                  child: Text(
                    'إضاءة مودة: استمع لشريكك باهتمام دون مقاطعة، فالهدف استكشاف طريقة التفكير وبناء الألفة لا إصدار الأحكام.',
                    style: TextStyle(fontSize: 10, height: 1.4, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),

          // Saved note preview if available
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sticky_note_2_rounded, size: 14, color: Colors.amber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'ملاحظتك: $note',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Spacer(),
          Center(
            child: TextButton.icon(
              onPressed: _flipCard,
              icon: const Icon(Icons.replay_rounded, size: 14),
              label: const Text('العودة لوجه السؤال', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // MODE 3: LUCKY WHEEL VIEW
  Widget _buildLuckyWheelView(bool isDark) {
    final categories = widget.questionService.categories;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'أدِر العجلة لاختيار محور الحوار عشوائياً',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'دعوا الأقدار تختار لكم موضوع النقاش القادم!',
              style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
            ),
            const SizedBox(height: 24),

            // Animated Custom Painted Wheel
            SizedBox(
              width: 270,
              height: 270,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Spinning Wheel Body
                  Transform.rotate(
                    angle: _wheelAnimation.value,
                    child: CustomPaint(
                      size: const Size(260, 260),
                      painter: _LuckyWheelPainter(categories: categories),
                    ),
                  ),

                  // Center spin button
                  GestureDetector(
                    onTap: _spinWheel,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.secondary, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _wheelSpinning
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.secondary),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 24),
                                  Text('تدوير', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                      ),
                    ),
                  ),

                  // Pointer Arrow at top
                  Positioned(
                    top: 0,
                    child: Container(
                      width: 20,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_drop_down, color: Colors.black, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Landed Category Result Box
            if (_wheelLandedCategory != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Color(int.parse(_wheelLandedCategory!.colorHex.replaceFirst('#', '0xFF'))),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '🎉 وقع الاختيار على:',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _wheelLandedCategory!.nameArabic,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(int.parse(_wheelLandedCategory!.colorHex.replaceFirst('#', '0xFF'))),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        final catQuestions = widget.questionService.getQuestionsByCategory(_wheelLandedCategory!.id);
                        if (catQuestions.isNotEmpty) {
                          setState(() {
                            _questions = List.from(catQuestions)..shuffle();
                            _currentIndex = 0;
                            _gameMode = 'deck';
                          });
                        }
                      },
                      child: const Text('بدء بطاقات هذا المحور 🃏', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // MODE 4: RAPID THIS-OR-THAT DILEMMA VIEW
  Widget _buildRapidDilemmaView(bool isDark) {
    final item = kRapidPairs[_rapidIndex];
    final groomSel = _rapidGroomChoice[_rapidIndex];
    final brideSel = _rapidBrideChoice[_rapidIndex];
    final bothSelected = groomSel != null && brideSel != null;
    final isMatch = bothSelected && groomSel == brideSel;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Category tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'بطاقة ${_rapidIndex + 1} من ${kRapidPairs.length} · ${item.category}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber),
              ),
            ),
            const SizedBox(height: 14),

            // Card with Option A & Option B
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.secondary.withOpacity(0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Option A
                  GestureDetector(
                    onTap: () {
                      _triggerHaptic();
                      setState(() {
                        if (_couplesTurnGroom) {
                          _rapidGroomChoice[_rapidIndex] = 'A';
                          _couplesTurnGroom = false;
                        } else {
                          _rapidBrideChoice[_rapidIndex] = 'A';
                          _couplesTurnGroom = true;
                        }
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (groomSel == 'A' || brideSel == 'A')
                            ? AppColors.primary.withOpacity(0.12)
                            : (isDark ? Colors.black26 : const Color(0xFFF9F7F1)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (groomSel == 'A' || brideSel == 'A')
                              ? AppColors.primary
                              : (isDark ? AppColors.borderDark : AppColors.borderLight),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(item.iconA, style: const TextStyle(fontSize: 32)),
                          const SizedBox(height: 6),
                          Text(
                            item.optionA,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text('خيار (أ)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('— أَوْ —', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),

                  // Option B
                  GestureDetector(
                    onTap: () {
                      _triggerHaptic();
                      setState(() {
                        if (_couplesTurnGroom) {
                          _rapidGroomChoice[_rapidIndex] = 'B';
                          _couplesTurnGroom = false;
                        } else {
                          _rapidBrideChoice[_rapidIndex] = 'B';
                          _couplesTurnGroom = true;
                        }
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (groomSel == 'B' || brideSel == 'B')
                            ? AppColors.secondary.withOpacity(0.15)
                            : (isDark ? Colors.black26 : const Color(0xFFF9F7F1)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (groomSel == 'B' || brideSel == 'B')
                              ? AppColors.secondary
                              : (isDark ? AppColors.borderDark : AppColors.borderLight),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(item.iconB, style: const TextStyle(fontSize: 32)),
                          const SizedBox(height: 6),
                          Text(
                            item.optionB,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text('خيار (ب)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Reflection result if both chose
            if (bothSelected)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isMatch ? Colors.emerald.withOpacity(0.12) : Colors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isMatch ? Colors.emerald : Colors.amber),
                ),
                child: Column(
                  children: [
                    Text(
                      isMatch ? '🎉 تطابق رائع! كلاكما اختار نفس التفضيل.' : '💡 تنوع جميل يكمل كل منكما الآخر.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isMatch ? Colors.emerald : Colors.amber.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.reflectionTip,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 14),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: _rapidIndex > 0
                      ? () {
                          _triggerHaptic();
                          setState(() => _rapidIndex--);
                        }
                      : null,
                  child: const Text('السابق'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _rapidIndex < kRapidPairs.length - 1
                      ? () {
                          _triggerHaptic();
                          setState(() => _rapidIndex++);
                        }
                      : null,
                  child: const Text('البطاقة التالية 👈'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for 8-slice colorful Lucky Wheel
class _LuckyWheelPainter extends CustomPainter {
  final List<CategoryModel> categories;

  _LuckyWheelPainter({required this.categories});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (categories.isEmpty) return;

    final sweepAngle = (2 * math.pi) / categories.length;

    for (int i = 0; i < categories.length; i++) {
      final cat = categories[i];
      final color = Color(int.parse(cat.colorHex.replaceFirst('#', '0xFF')));

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final startAngle = i * sweepAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Border stroke between slices
      final strokePaint = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        strokePaint,
      );
    }

    // Outer gold rim
    final rimPaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(center, radius, rimPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
