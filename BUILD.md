# دليل بناء وتوليد حزمة أندرويد (BUILD.md)

يشرح هذا الدليل كيفية بناء حزمة التطبيق `app-release.apk` الخاصة بنظام Android لتطبيق مودة سواءً على جهاز المطور المحلي أو عبر خوادم البناء المؤتمتة (CI/CD).

---

## 🛠️ الطريقة الأولى: البناء المحلي باستخدام Flutter SDK

إذا كان لديك بيئة Flutter و Android SDK مثبتة ومجهزة على جهازك:

```bash
# 1. التحقق من سلامة البيئة
flutter doctor -v

# 2. جلب وتثبيت الحزم
flutter pub get

# 3. التحقق من خلو الكود من الأخطاء والتحذيرات
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test

# 4. بناء ملف APK موحد ومكتمل للإنتاج
flutter build apk --release
```

**مسار ملف الـ APK الناتج:**
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## ☁️ الطريقة الثانية: البناء السحابي المؤتمت عبر GitHub Actions

نظراً لأن بيئات التطوير السحابية المعزولة أو الحاويات الخفيفة (كحاويات gVisor/Docker المحدودة) لا تتضمن مسبقاً حزم Android SDK وضخامة ملفات Gradle/Java، فقد تم تجهيز سير عمل GitHub Actions كامل وموثق وجاهز للاستخدام مباشرة في المسار:
`.github/workflows/android-apk.yml`

### مواصفات سير العمل:
- **نظام التشغيل:** Ubuntu Latest
- **بيئة جافا:** Java 17 (Eclipse Temurin)
- **بيئة فلاتر:** Flutter Stable Channel (الإصدار 3.22.x)
- **الخطوات التلقائية:**
  1. `flutter pub get`
  2. `dart format check`
  3. `flutter analyze`
  4. `flutter test`
  5. `flutter build apk --release`
  6. `actions/upload-artifact@v4` لتنزيل الـ APK مباشرة من واجهة GitHub.

### كيفية التشغيل من GitHub:
1. ارفع المشروع إلى مستودع GitHub الخاص بك.
2. توجه إلى تبويب **Actions**.
3. اختر سير العمل: **Build Mawadda Release APK**.
4. اضغط على زر **Run workflow** (مشغل يدوياً عبر `workflow_dispatch`).
5. بمجرد انتهاء الخطوات بنجاح، ستجد ملف `mawadda-release-apk.zip` جاهزاً للتنزيل في قسم Artifacts.

### ملاحظة حول توقيع التطبيق (Signing Configuration):
تستخدم إعدادات الـ release الحالية شهادة التوقيع الافتراضية المناسبة للاختبار والتثبيت المباشر على أجهزة أندرويد (Sideloading). لنشر التطبيق على متجر Google Play، يرجى إنشاء مفتاح توقيع مخصص `keystore` وضبط `android/key.properties` وفق إرشادات توقيع أندرويد الرسمية.
