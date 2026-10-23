import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  final StorageService storageService;
  final Function(String) onThemeChanged;

  const SettingsScreen({
    Key? key,
    required this.storageService,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _currentTheme;

  @override
  void initState() {
    super.initState();
    _currentTheme = widget.storageService.getThemeMode();
  }

  void _changeTheme(String mode) async {
    await widget.storageService.setThemeMode(mode);
    setState(() {
      _currentTheme = mode;
    });
    widget.onThemeChanged(mode);
  }

  void _confirmResetProgress() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد إعادة ضبط التقدم'),
        content: const Text('هل أنت متأكد من تصفير سجل الأسئلة المستكشفة والجلسات الحالية؟ لن يتم حذف أسئلتك المفضلة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await widget.storageService.resetProgress();
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تمت إعادة ضبط سجل التقدم بنجاح')),
                );
              }
            },
            child: const Text('نعم، إعادة الضبط'),
          ),
        ],
      ),
    );
  }

  void _showIslamicGuidelines() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: ListView(
            controller: scrollController,
            children: const [
              Center(
                child: Text(
                  'الضوابط والمنهجية الشرعية لمودة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'تمت صياغة جميع أسئلة ومحاور تطبيق "مودة" بعناية فائقة وفق الضوابط التالية:',
                style: TextStyle(fontWeight: FontWeight.w600, height: 1.5),
              ),
              SizedBox(height: 12),
              Text('١. العفة وصون الحياء: تجنب أي ألفاظ أو إيحاءات تخدش الحياء، والتركيز على مكارم الأخلاق والمسؤوليات.'),
              SizedBox(height: 8),
              Text('٢. ستر العورات وحفظ الخصوصية: لا يتضمن التطبيق أي سؤال يستدعي كشف ذنوب ماضية أو خصوصيات منهي عن إفشائها شرعاً.'),
              SizedBox(height: 8),
              Text('٣. احترام البيئة الأسرية: تشجيع اللقاءات في حضور الأهل والأجواء المشروعة شرعاً وعرفاً دون خلوة محرمة.'),
              SizedBox(height: 8),
              Text('٤. الأمانة العلمية: خلو التطبيق تماماً من أي أحاديث موضوعة أو تأويلات متكلفة، مع الاستناد للمقاصد الإسلامية في الزواج والرحمة.'),
              SizedBox(height: 8),
              Text('٥. عدم ادعاء الغيب: التطبيق وسيلة حوار وتفاهم، ولا يزعم قياس التوافق القطعي أو التنبؤ بمستقبل العلاقة.'),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'مودة (Mawadda)',
      applicationVersion: '1.0.0',
      applicationLegalese: 'تطبيق بطاقات حوارية إسلامية هادفة للتعارف الجاد قبل الزواج.\nيعمل محلياً بالكامل دون إنترنت ولا يجمع أي بيانات شخصية.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات والضوابط'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Theme section
          const Text(
            'المظهر والتصميم',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('مظهر النظام التلقائي'),
                  value: 'system',
                  groupValue: _currentTheme,
                  onChanged: (val) => _changeTheme(val!),
                ),
                RadioListTile<String>(
                  title: const Text('الوضع النهاري (فاتح)'),
                  value: 'light',
                  groupValue: _currentTheme,
                  onChanged: (val) => _changeTheme(val!),
                ),
                RadioListTile<String>(
                  title: const Text('الوضع الليلي (داكن)'),
                  value: 'dark',
                  groupValue: _currentTheme,
                  onChanged: (val) => _changeTheme(val!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Content & Islamic Guidelines
          const Text(
            'المحتوى والضوابط الشرعية',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
                  title: const Text('الضوابط الشرعية للمحتوى'),
                  subtitle: const Text('المنهج الأخلاقي والشرعي المعتمد في التطبيق'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: _showIslamicGuidelines,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.shield_outlined, color: AppColors.secondary),
                  title: const Text('سياسة الخصوصية'),
                  subtitle: const Text('يعمل التطبيق دون إنترنت وبدون جمع بيانات إطلاقاً'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('الخصوصية والأمان'),
                        content: const Text(
                          'تطبيق مودة يحترم خصوصيتكما التامة:\n\n'
                          '• التطبيق يعمل بالكامل دون حاجة للاتصال بالإنترنت (Offline 100%).\n'
                          '• لا يتطلب إنشاء حساب أو تسجيل دخول أو إدخال أي أسماء أو أرقام هواتف.\n'
                          '• يتم حفظ تفضيلاتك (الأسئلة المفضلة والمظهر والتقدم) محلياً فقط على جهازك.\n'
                          '• لا توجد أي أدوات تتبع أو تحليلات طرف ثالث.',
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسناً')),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: AppColors.primaryLight),
                  title: const Text('عن تطبيق مودة'),
                  subtitle: const Text('الإصدار والرؤية'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: _showAbout,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Data management
          const Text(
            'إدارة البيانات والمحفوظات',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.refresh_rounded, color: AppColors.warning),
                  title: const Text('إعادة ضبط سجل التقدم'),
                  subtitle: const Text('تصفير نسبة الأسئلة المستكشفة'),
                  onTap: _confirmResetProgress,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restart_alt_rounded, color: Colors.grey),
                  title: const Text('إعادة عرض شاشات الترحيب'),
                  subtitle: const Text('إعادة فتح جولة التعريف عند تشغيل التطبيق'),
                  onTap: () async {
                    await widget.storageService.resetOnboarding();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('سيتم عرض شاشات الترحيب في التشغيل القادم')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
