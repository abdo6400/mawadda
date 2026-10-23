import React, { useState, useEffect } from 'react';
import {
  Heart,
  Bookmark,
  Settings,
  ArrowRight,
  ArrowLeft,
  RotateCcw,
  Sparkles,
  Home,
  Grid,
  CheckCircle2,
  HelpCircle,
  Moon,
  Sun,
  Shield,
  BookOpen,
  Info,
  ChevronLeft,
  Layers,
  Smartphone,
  Maximize2,
  FileCode,
  Download,
  Copy,
  Check,
  Play
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { MAWADDA_DATA, Question, Category } from './data/questionsData';
import { soundManager } from './utils/audio';
import { usePWAInstall } from './utils/usePWAInstall';

type Screen = 'splash' | 'onboarding' | 'home' | 'categories' | 'game' | 'session' | 'favorites' | 'settings';

interface ActiveSession {
  title: string;
  questionIds: string[];
  currentIndex: number;
  categoryIds: string[];
}

export default function App() {
  const { isInstallable, isInstalled, isIOS, install: installPWA } = usePWAInstall();
  const [showInstallModal, setShowInstallModal] = useState<boolean>(false);

  // Persistence state
  const [theme, setTheme] = useState<'light' | 'dark'>(() => {
    return (localStorage.getItem('mawadda_theme') as 'light' | 'dark') || 'light';
  });

  const [onboardingDone, setOnboardingDone] = useState<boolean>(() => {
    return localStorage.getItem('mawadda_onboarding_completed') === 'true';
  });

  const [favorites, setFavorites] = useState<string[]>(() => {
    try {
      return JSON.parse(localStorage.getItem('mawadda_favorites') || '[]');
    } catch {
      return [];
    }
  });

  const [exploredIds, setExploredIds] = useState<string[]>(() => {
    try {
      return JSON.parse(localStorage.getItem('mawadda_explored_ids') || '[]');
    } catch {
      return [];
    }
  });

  const [activeSession, setActiveSession] = useState<ActiveSession | null>(() => {
    try {
      const raw = localStorage.getItem('mawadda_active_session');
      return raw ? JSON.parse(raw) : null;
    } catch {
      return null;
    }
  });

  // UI Navigation state
  const [currentScreen, setCurrentScreen] = useState<Screen>('splash');
  const [phoneFrame, setPhoneFrame] = useState<boolean>(true);
  const [onboardingStep, setOnboardingStep] = useState<number>(0);

  // Game / Session state
  const [gameQuestions, setGameQuestions] = useState<Question[]>([]);
  const [gameIndex, setGameIndex] = useState<number>(0);
  const [showFollowUp, setShowFollowUp] = useState<boolean>(false);
  const [gameCategory, setGameCategory] = useState<Category | null>(null);

  // Custom Session Creator state
  const [selectedCats, setSelectedCats] = useState<string[]>(MAWADDA_DATA.categories.map(c => c.id));
  const [selectedLevel, setSelectedLevel] = useState<number | null>(null);
  const [sessionCount, setSessionCount] = useState<number>(15);

  // Modals state
  const [showIslamicGuidelines, setShowIslamicGuidelines] = useState<boolean>(false);
  const [showAboutModal, setShowAboutModal] = useState<boolean>(false);
  const [showPrivacyModal, setShowPrivacyModal] = useState<boolean>(false);
  const [showFlutterDrawer, setShowFlutterDrawer] = useState<boolean>(false);
  const [copiedWorkflow, setCopiedWorkflow] = useState<boolean>(false);
  const [levelPickerCategory, setLevelPickerCategory] = useState<Category | null>(null);
  const [showCompletionModal, setShowCompletionModal] = useState<boolean>(false);
  const [favCategoryFilter, setFavCategoryFilter] = useState<string | null>(null);

  // Synchronize theme to document body
  useEffect(() => {
    localStorage.setItem('mawadda_theme', theme);
    if (theme === 'dark') {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }, [theme]);

  // Synchronize favorites
  useEffect(() => {
    localStorage.setItem('mawadda_favorites', JSON.stringify(favorites));
  }, [favorites]);

  // Synchronize explored
  useEffect(() => {
    localStorage.setItem('mawadda_explored_ids', JSON.stringify(exploredIds));
  }, [exploredIds]);

  // Synchronize active session
  useEffect(() => {
    if (activeSession) {
      localStorage.setItem('mawadda_active_session', JSON.stringify(activeSession));
    } else {
      localStorage.removeItem('mawadda_active_session');
    }
  }, [activeSession]);

  // Splash timeout
  useEffect(() => {
    if (currentScreen === 'splash') {
      const timer = setTimeout(() => {
        if (onboardingDone) {
          setCurrentScreen('home');
        } else {
          setCurrentScreen('onboarding');
        }
      }, 1600);
      return () => clearTimeout(timer);
    }
  }, [currentScreen, onboardingDone]);

  // Mark current game question as explored
  useEffect(() => {
    if (currentScreen === 'game' && gameQuestions[gameIndex]) {
      const qId = gameQuestions[gameIndex].id;
      if (!exploredIds.includes(qId)) {
        setExploredIds(prev => [...prev, qId]);
      }
    }
  }, [currentScreen, gameIndex, gameQuestions, exploredIds]);

  // Toggle favorite
  const handleToggleFavorite = (qId: string) => {
    soundManager.playCardClick();
    setFavorites(prev => {
      const isFav = prev.includes(qId);
      if (isFav) {
        return prev.filter(id => id !== qId);
      } else {
        soundManager.playChime();
        return [...prev, qId];
      }
    });
  };

  // Launch a game with specific question array
  const startGame = (questions: Question[], category?: Category | null, title?: string) => {
    if (!questions || questions.length === 0) return;
    soundManager.playCardClick();
    setGameQuestions(questions);
    setGameIndex(0);
    setShowFollowUp(false);
    setGameCategory(category || null);
    setCurrentScreen('game');

    // Also register active session
    setActiveSession({
      title: title || (category ? category.nameArabic : 'جلسة حوار مودة'),
      questionIds: questions.map(q => q.id),
      currentIndex: 0,
      categoryIds: category ? [category.id] : []
    });
  };

  // Start category game
  const startCategoryGame = (catId: string, level?: number | null) => {
    const cat = MAWADDA_DATA.categories.find(c => c.id === catId);
    let qs = MAWADDA_DATA.questions.filter(q => q.categoryId === catId);
    if (level) {
      qs = qs.filter(q => q.level === level);
    }
    const title = level
      ? `${cat?.nameArabic} — المستوى ${level}`
      : `${cat?.nameArabic} (المحور كاملاً)`;
    startGame(qs, cat, title);
    setLevelPickerCategory(null);
  };

  // Start custom session
  const startCustomSession = () => {
    if (selectedCats.length === 0) return;
    soundManager.playCardClick();

    let pool = MAWADDA_DATA.questions.filter(q => selectedCats.includes(q.categoryId));
    if (selectedLevel) {
      pool = pool.filter(q => q.level === selectedLevel);
    }
    // Shuffle pool
    const shuffled = [...pool].sort(() => 0.5 - Math.random());
    const chosen = shuffled.slice(0, sessionCount);

    const title = selectedLevel
      ? `جلسة مخصصة — مستوى ${selectedLevel} (${chosen.length} بطاقة)`
      : `جلسة حوار شاملة (${chosen.length} بطاقة)`;

    startGame(chosen, null, title);
  };

  // Start favorites session
  const startFavoritesSession = (filteredList: Question[]) => {
    if (filteredList.length === 0) return;
    soundManager.playCardClick();
    startGame(filteredList, null, `جلسة الأسئلة المفضلة (${filteredList.length} بطاقة)`);
  };

  // Next question
  const handleNextQuestion = () => {
    soundManager.playCardClick();
    if (gameIndex < gameQuestions.length - 1) {
      const nextIdx = gameIndex + 1;
      setGameIndex(nextIdx);
      setShowFollowUp(false);
      if (activeSession) {
        setActiveSession({ ...activeSession, currentIndex: nextIdx });
      }
    } else {
      soundManager.playChime();
      setShowCompletionModal(true);
    }
  };

  // Previous question
  const handlePrevQuestion = () => {
    soundManager.playCardClick();
    if (gameIndex > 0) {
      const prevIdx = gameIndex - 1;
      setGameIndex(prevIdx);
      setShowFollowUp(false);
      if (activeSession) {
        setActiveSession({ ...activeSession, currentIndex: prevIdx });
      }
    }
  };

  // Resume active session
  const resumeActiveSession = () => {
    if (!activeSession) return;
    soundManager.playCardClick();
    const qs = activeSession.questionIds
      .map(id => MAWADDA_DATA.questions.find(q => q.id === id))
      .filter((q): q is Question => q !== undefined);

    if (qs.length > 0) {
      setGameQuestions(qs);
      setGameIndex(Math.min(activeSession.currentIndex, qs.length - 1));
      setShowFollowUp(false);
      setGameCategory(null);
      setCurrentScreen('game');
    }
  };

  // Finish onboarding
  const completeOnboarding = () => {
    soundManager.playCardClick();
    localStorage.setItem('mawadda_onboarding_completed', 'true');
    setOnboardingDone(true);
    setCurrentScreen('home');
  };

  // Reset all explored progress
  const resetProgress = () => {
    if (window.confirm('هل أنت متأكد من إعادة ضبط سجل الأسئلة المستكشفة والجلسات الجارية؟ لن يتم حذف أسئلتك المفضلة.')) {
      setExploredIds([]);
      setActiveSession(null);
      localStorage.removeItem('mawadda_explored_ids');
      localStorage.removeItem('mawadda_active_session');
      alert('تمت إعادة ضبط سجل التقدم بنجاح.');
    }
  };

  // Reset onboarding
  const resetOnboarding = () => {
    localStorage.removeItem('mawadda_onboarding_completed');
    setOnboardingDone(false);
    setOnboardingStep(0);
    setCurrentScreen('onboarding');
  };

  // Copy Github workflow yaml
  const copyWorkflowYaml = () => {
    const yaml = `name: Build Mawadda Release APK

on:
  workflow_dispatch:
  push:
    branches: [ main, master ]
  pull_request:
    branches: [ main, master ]

jobs:
  build:
    name: Build Android APK
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Set up Java 17
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.x'
          channel: 'stable'
          cache: true

      - name: Verify Flutter Installation
        run: flutter doctor -v

      - name: Install Dependencies
        run: flutter pub get

      - name: Run Dart Formatter Check
        run: dart format --output=none --set-exit-if-changed .

      - name: Analyze Project Code
        run: flutter analyze

      - name: Run Unit & Widget Tests
        run: flutter test

      - name: Build Universal Release APK
        run: flutter build apk --release

      - name: Upload Release APK Artifact
        uses: actions/upload-artifact@v4
        with:
          name: mawadda-release-apk
          path: build/app/outputs/flutter-apk/app-release.apk
          if-no-files-found: error`;
    navigator.clipboard.writeText(yaml);
    setCopiedWorkflow(true);
    setTimeout(() => setCopiedWorkflow(false), 2000);
  };

  // Download questions.json
  const downloadQuestionsJson = () => {
    const dataStr = 'data:text/json;charset=utf-8,' + encodeURIComponent(JSON.stringify(MAWADDA_DATA, null, 2));
    const dlAnchorElem = document.createElement('a');
    dlAnchorElem.setAttribute('href', dataStr);
    dlAnchorElem.setAttribute('download', 'questions.json');
    dlAnchorElem.click();
  };

  // Helper for category icon
  const renderCategoryIcon = (icon: string, color: string) => {
    const props = { size: 22, style: { color } };
    switch (icon) {
      case 'HeartHandshake':
        return <Heart {...props} />;
      case 'Compass':
        return <BookOpen {...props} />;
      case 'Users':
        return <Layers {...props} />;
      case 'Home':
        return <Home {...props} />;
      case 'Coins':
        return <Sparkles {...props} />;
      default:
        return <Heart {...props} />;
    }
  };

  // Current question data
  const currentQ = gameQuestions[gameIndex];
  const isCurrentFav = currentQ ? favorites.includes(currentQ.id) : false;
  const currentCat = currentQ ? MAWADDA_DATA.categories.find(c => c.id === currentQ.categoryId) : null;
  const currentCatColor = currentCat ? currentCat.colorHex : '#176B5B';

  return (
    <div className={`min-h-screen flex flex-col items-center justify-start ${theme === 'dark' ? 'bg-[#0A1613] text-[#F3F1EC]' : 'bg-[#F2ECE1] text-[#252525]'} transition-colors duration-300 font-['Tajawal'] select-none`}>
      {/* Top Bar for View Controls & Flutter Hub */}
      <header className="w-full bg-white/70 dark:bg-[#112420]/80 backdrop-blur-md border-b border-[#E7E1D5] dark:border-[#203D35] px-4 py-2 flex items-center justify-between z-30 sticky top-0">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-full bg-[#176B5B] flex items-center justify-center text-[#C8A96B] font-bold text-lg shadow-sm">
            م
          </div>
          <div>
            <h1 className="font-bold text-sm tracking-wide text-[#176B5B] dark:text-[#32A790]">مودة (Mawadda)</h1>
            <p className="text-[10px] text-gray-500 dark:text-gray-400">تطبيق بطاقات حوارية إسلامية قبل الزواج</p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          {/* Direct Install on Phone button */}
          <button
            onClick={() => {
              if (isInstallable) {
                installPWA();
              } else {
                setShowInstallModal(true);
              }
            }}
            className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-bold rounded-lg bg-[#176B5B] hover:bg-[#12574A] text-white transition shadow-xs"
            title="تثبيت التطبيق على هاتفك"
          >
            <Smartphone size={14} />
            <span>{isInstalled ? 'التطبيق مُثبّت' : 'تثبيت على الهاتف'}</span>
          </button>

          {/* Flutter & APK Hub trigger */}
          <button
            onClick={() => setShowFlutterDrawer(true)}
            className="hidden sm:flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold rounded-lg bg-[#C8A96B]/15 text-[#9E7B35] dark:text-[#DFC894] hover:bg-[#C8A96B]/25 transition border border-[#C8A96B]/30"
            title="ملفات مشروع Flutter وسير عمل الـ APK"
          >
            <FileCode size={14} />
            <span>كود Flutter و APK</span>
          </button>

          {/* Phone Frame Toggle */}
          <button
            onClick={() => setPhoneFrame(!phoneFrame)}
            className="p-1.5 rounded-lg border border-gray-300 dark:border-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 transition"
            title={phoneFrame ? 'عرض كامل الشاشة' : 'عرض محاكي الهاتف'}
          >
            {phoneFrame ? <Maximize2 size={16} /> : <Smartphone size={16} />}
          </button>

          {/* Theme toggle */}
          <button
            onClick={() => setTheme(theme === 'light' ? 'dark' : 'light')}
            className="p-1.5 rounded-lg border border-gray-300 dark:border-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 transition"
            title="تبديل المظهر النهاري/الليلي"
          >
            {theme === 'light' ? <Moon size={16} /> : <Sun size={16} />}
          </button>
        </div>
      </header>

      {/* Main Container: either phone mockup or full width */}
      <main className={`flex-1 w-full flex justify-center py-4 px-2 sm:px-4 ${phoneFrame ? 'max-w-md' : 'max-w-4xl'}`}>
        <div className={`w-full relative overflow-hidden transition-all duration-300 ${phoneFrame ? 'rounded-[38px] border-[8px] border-[#222E2B] shadow-2xl min-h-[780px] max-h-[880px] flex flex-col bg-[#FAF8F3] dark:bg-[#0E1D19]' : 'rounded-2xl border border-[#E7E1D5] dark:border-[#203D35] bg-[#FAF8F3] dark:bg-[#0E1D19] shadow-lg flex flex-col min-h-[750px]'}`}>

          {/* Device Mockup Status bar when in phoneFrame mode */}
          {phoneFrame && (
            <div className="w-full pt-2 px-6 flex justify-between items-center text-[11px] font-semibold text-gray-500 dark:text-gray-400 select-none z-20">
              <span>9:41</span>
              <div className="w-20 h-4 bg-black/80 rounded-full mx-auto" />
              <div className="flex items-center gap-1">
                <span>5G</span>
                <span className="w-4 h-2.5 border border-current rounded-sm inline-block relative after:content-[''] after:w-2.5 after:h-1.5 after:bg-current after:absolute after:top-0.5 after:left-0.5" />
              </div>
            </div>
          )}

          {/* SCREEN: SPLASH */}
          {currentScreen === 'splash' && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="flex-1 flex flex-col items-center justify-center p-8 text-center"
            >
              <motion.div
                initial={{ scale: 0.8, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                transition={{ duration: 0.8, ease: 'easeOut' }}
                className="w-28 h-28 rounded-full bg-gradient-to-tr from-[#176B5B] to-[#238A76] flex items-center justify-center shadow-xl border-4 border-[#C8A96B]"
              >
                <Heart size={54} className="text-[#C8A96B] fill-[#C8A96B]/20" />
              </motion.div>
              <motion.h2
                initial={{ y: 20, opacity: 0 }}
                animate={{ y: 0, opacity: 1 }}
                transition={{ delay: 0.3 }}
                className="mt-6 text-4xl font-extrabold text-[#176B5B] dark:text-[#32A790] tracking-wide"
              >
                مَـوَدَّة
              </motion.h2>
              <motion.p
                initial={{ y: 20, opacity: 0 }}
                animate={{ y: 0, opacity: 1 }}
                transition={{ delay: 0.5 }}
                className="mt-2 text-sm text-[#C8A96B] font-semibold"
              >
                رحلة حوار هادفة لبناء بيت مسلم مستقر
              </motion.p>
              <div className="mt-8 flex gap-2">
                <span className="w-2 h-2 rounded-full bg-[#176B5B] animate-ping" />
                <span className="w-2 h-2 rounded-full bg-[#C8A96B]" />
              </div>
            </motion.div>
          )}

          {/* SCREEN: ONBOARDING */}
          {currentScreen === 'onboarding' && (
            <div className="flex-1 flex flex-col justify-between p-6">
              <div className="flex justify-between items-center">
                <span className="text-xs font-bold text-[#176B5B] dark:text-[#32A790]">
                  الخطوة {onboardingStep + 1} من 3
                </span>
                <button
                  onClick={completeOnboarding}
                  className="text-xs font-bold text-[#C8A96B] hover:underline"
                >
                  تخطي
                </button>
              </div>

              {/* Onboarding Steps Carousel */}
              <div className="my-auto py-6">
                <AnimatePresence mode="wait">
                  {onboardingStep === 0 && (
                    <motion.div
                      key="step-0"
                      initial={{ opacity: 0, x: -30 }}
                      animate={{ opacity: 1, x: 0 }}
                      exit={{ opacity: 0, x: 30 }}
                      className="text-center"
                    >
                      <div className="w-24 h-24 mx-auto rounded-full bg-[#176B5B]/10 dark:bg-[#176B5B]/20 flex items-center justify-center border-2 border-[#C8A96B]/60 mb-6">
                        <BookOpen size={44} className="text-[#176B5B] dark:text-[#32A790]" />
                      </div>
                      <h3 className="text-2xl font-extrabold text-[#176B5B] dark:text-[#32A790] mb-3">
                        تعارف هادف
                      </h3>
                      <p className="text-sm text-gray-600 dark:text-gray-300 leading-relaxed max-w-xs mx-auto">
                        أسئلة تساعدك على معرفة الطرف الآخر بوضوح واحترام في أجواء أسرية آمنة ومريحة.
                      </p>
                    </motion.div>
                  )}

                  {onboardingStep === 1 && (
                    <motion.div
                      key="step-1"
                      initial={{ opacity: 0, x: -30 }}
                      animate={{ opacity: 1, x: 0 }}
                      exit={{ opacity: 0, x: 30 }}
                      className="text-center"
                    >
                      <div className="w-24 h-24 mx-auto rounded-full bg-[#176B5B]/10 dark:bg-[#176B5B]/20 flex items-center justify-center border-2 border-[#C8A96B]/60 mb-6">
                        <Sparkles size={44} className="text-[#C8A96B]" />
                      </div>
                      <h3 className="text-2xl font-extrabold text-[#176B5B] dark:text-[#32A790] mb-3">
                        حوار أعمق
                      </h3>
                      <p className="text-sm text-gray-600 dark:text-gray-300 leading-relaxed max-w-xs mx-auto">
                        اكتشف القيم والأفكار والتوقعات الجوهرية قبل الزواج لتأسيس شراكة واعية ومستقرة.
                      </p>
                    </motion.div>
                  )}

                  {onboardingStep === 2 && (
                    <motion.div
                      key="step-2"
                      initial={{ opacity: 0, x: -30 }}
                      animate={{ opacity: 1, x: 0 }}
                      exit={{ opacity: 0, x: 30 }}
                      className="text-center"
                    >
                      <div className="w-24 h-24 mx-auto rounded-full bg-[#176B5B]/10 dark:bg-[#176B5B]/20 flex items-center justify-center border-2 border-[#C8A96B]/60 mb-6">
                        <Shield size={44} className="text-[#176B5B] dark:text-[#32A790]" />
                      </div>
                      <h3 className="text-2xl font-extrabold text-[#176B5B] dark:text-[#32A790] mb-3">
                        بضوابط شرعية
                      </h3>
                      <p className="text-sm text-gray-600 dark:text-gray-300 leading-relaxed max-w-xs mx-auto">
                        مساحة للحوار الجاد مع مراعاة الآداب الإسلامية وحفظ الخصوصية وصون العورات والحياء.
                      </p>
                    </motion.div>
                  )}
                </AnimatePresence>

                {/* Dots indicator */}
                <div className="flex justify-center gap-2 mt-8">
                  {[0, 1, 2].map(idx => (
                    <div
                      key={idx}
                      className={`h-2 rounded-full transition-all duration-300 ${onboardingStep === idx ? 'w-6 bg-[#176B5B] dark:bg-[#32A790]' : 'w-2 bg-gray-300 dark:bg-gray-600'}`}
                    />
                  ))}
                </div>
              </div>

              {/* Disclaimer notice */}
              <div className="bg-[#C8A96B]/15 dark:bg-[#C8A96B]/10 border border-[#C8A96B]/40 rounded-xl p-3 flex items-start gap-2 text-xs text-gray-700 dark:text-gray-300 mb-4">
                <Info size={16} className="text-[#C8A96B] shrink-0 mt-0.5" />
                <p className="leading-snug">
                  تطبيق مودة وسيلة مساعدة لفتح آفاق الحوار والتفاهم، وليس فتوى شرعية أو أداة تقييم توافق قطعية.
                </p>
              </div>

              {/* Action button */}
              <button
                onClick={() => {
                  soundManager.playCardClick();
                  if (onboardingStep < 2) {
                    setOnboardingStep(prev => prev + 1);
                  } else {
                    completeOnboarding();
                  }
                }}
                className="w-full py-3.5 rounded-xl bg-[#176B5B] hover:bg-[#12574A] text-white font-bold text-sm shadow-md transition flex items-center justify-center gap-2"
              >
                <span>{onboardingStep === 2 ? 'ابدأ الآن' : 'المتابعة'}</span>
                <ArrowLeft size={16} />
              </button>
            </div>
          )}

          {/* SCREEN: HOME */}
          {currentScreen === 'home' && (
            <div className="flex-1 flex flex-col justify-between overflow-y-auto">
              <div className="p-5 space-y-4">
                {/* Spiritual Header Card */}
                <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-[#176B5B] to-[#0F493E] text-white p-5 shadow-md border border-[#C8A96B]/40">
                  <div className="flex items-center gap-2 text-[#C8A96B] text-xs font-bold mb-1">
                    <Heart size={14} className="fill-[#C8A96B]" />
                    <span>سَكَنٌ وَمَوَدَّةٌ وَرَحْمَة</span>
                  </div>
                  <h3 className="font-bold text-lg leading-tight mb-2">
                    مرحباً بكما في مودة
                  </h3>
                  <p className="text-xs text-white/80 leading-relaxed mb-4">
                    حوار هادف يبني جسور الألفة، ويكشف المشتركات ويضع أركان الشراكة الصادقة قبل الزواج.
                  </p>

                  {/* Progress tracker */}
                  <div className="bg-white/10 rounded-xl p-3 backdrop-blur-xs">
                    <div className="flex justify-between text-xs mb-1.5 font-semibold">
                      <span>الأسئلة المستكشفة: {exploredIds.length} من {MAWADDA_DATA.totalQuestions}</span>
                      <span className="text-[#C8A96B]">{Math.round((exploredIds.length / MAWADDA_DATA.totalQuestions) * 100)}%</span>
                    </div>
                    <div className="w-full bg-black/20 h-2 rounded-full overflow-hidden">
                      <div
                        className="bg-gradient-to-r from-[#C8A96B] to-[#DFC894] h-full rounded-full transition-all duration-500"
                        style={{ width: `${(exploredIds.length / MAWADDA_DATA.totalQuestions) * 100}%` }}
                      />
                    </div>
                  </div>
                </div>

                {/* Continue Previous Session Card if exists */}
                {activeSession && (
                  <div className="p-4 rounded-xl bg-white dark:bg-[#162B26] border border-[#C8A96B]/40 shadow-sm flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-full bg-[#C8A96B]/20 text-[#9E7B35] dark:text-[#C8A96B] flex items-center justify-center">
                        <Play size={18} className="fill-current mr-0.5" />
                      </div>
                      <div>
                        <div className="text-xs font-bold text-[#176B5B] dark:text-[#32A790]">جلسة حوار جارية</div>
                        <div className="text-xs text-gray-600 dark:text-gray-300 font-semibold">{activeSession.title}</div>
                        <div className="text-[10px] text-gray-400 mt-0.5">البطاقة {activeSession.currentIndex + 1} من {activeSession.questionIds.length}</div>
                      </div>
                    </div>
                    <button
                      onClick={resumeActiveSession}
                      className="px-3.5 py-1.5 text-xs font-bold rounded-lg bg-[#176B5B] text-white hover:bg-[#12574A] transition"
                    >
                      استئناف
                    </button>
                  </div>
                )}

                {/* Featured: Start Custom Session */}
                <div
                  onClick={() => {
                    soundManager.playCardClick();
                    setCurrentScreen('session');
                  }}
                  className="p-4 rounded-2xl bg-[#C8A96B]/15 dark:bg-[#C8A96B]/10 border border-[#C8A96B]/50 hover:border-[#C8A96B] transition cursor-pointer shadow-sm group"
                >
                  <div className="flex justify-between items-start">
                    <div>
                      <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-[#C8A96B] text-black">جلسة موجهة</span>
                      <h4 className="font-bold text-base text-[#176B5B] dark:text-[#32A790] mt-1">ابدأ رحلة التعارف</h4>
                      <p className="text-xs text-gray-600 dark:text-gray-300 mt-1">
                        خصص محاور ومستوى الحوار لتبدأ جلسة بطاقات ممتعة متدرجة.
                      </p>
                    </div>
                    <div className="w-9 h-9 rounded-full bg-[#176B5B] text-white flex items-center justify-center group-hover:scale-105 transition">
                      <ArrowLeft size={16} />
                    </div>
                  </div>
                </div>

                {/* Shortcuts Row */}
                <div className="grid grid-cols-2 gap-3">
                  <div
                    onClick={() => {
                      soundManager.playCardClick();
                      setCurrentScreen('favorites');
                    }}
                    className="p-3.5 rounded-xl bg-white dark:bg-[#162B26] border border-[#E7E1D5] dark:border-[#203D35] hover:border-[#C8A96B] transition cursor-pointer flex items-center gap-2.5"
                  >
                    <div className="w-8 h-8 rounded-full bg-red-100 dark:bg-red-950/50 text-red-500 flex items-center justify-center">
                      <Bookmark size={16} className="fill-current" />
                    </div>
                    <div>
                      <div className="text-xs font-bold">المفضلة</div>
                      <div className="text-[10px] text-gray-500 dark:text-gray-400">{favorites.length} أسئلة محفوظة</div>
                    </div>
                  </div>

                  <div
                    onClick={() => {
                      soundManager.playCardClick();
                      setCurrentScreen('categories');
                    }}
                    className="p-3.5 rounded-xl bg-white dark:bg-[#162B26] border border-[#E7E1D5] dark:border-[#203D35] hover:border-[#176B5B] transition cursor-pointer flex items-center gap-2.5"
                  >
                    <div className="w-8 h-8 rounded-full bg-[#176B5B]/15 text-[#176B5B] dark:text-[#32A790] flex items-center justify-center">
                      <Grid size={16} />
                    </div>
                    <div>
                      <div className="text-xs font-bold">كل المحاور</div>
                      <div className="text-[10px] text-gray-500 dark:text-gray-400">6 مجالات حوارية</div>
                    </div>
                  </div>
                </div>

                {/* Categories Overview List */}
                <div>
                  <div className="flex justify-between items-center mb-2.5">
                    <h4 className="font-bold text-sm text-gray-800 dark:text-gray-200">المحاور الرئيسية (180 سؤالاً)</h4>
                    <button
                      onClick={() => setCurrentScreen('categories')}
                      className="text-xs text-[#176B5B] dark:text-[#32A790] font-semibold hover:underline"
                    >
                      تصفح الكل
                    </button>
                  </div>

                  <div className="space-y-2">
                    {MAWADDA_DATA.categories.map(cat => {
                      const catQuestions = MAWADDA_DATA.questions.filter(q => q.categoryId === cat.id);
                      const exploredInCat = catQuestions.filter(q => exploredIds.includes(q.id)).length;

                      return (
                        <div
                          key={cat.id}
                          onClick={() => {
                            soundManager.playCardClick();
                            setLevelPickerCategory(cat);
                          }}
                          className="p-3 rounded-xl bg-white dark:bg-[#162B26] border border-[#E7E1D5] dark:border-[#203D35] hover:shadow-sm transition cursor-pointer flex items-center justify-between"
                        >
                          <div className="flex items-center gap-3">
                            <div
                              className="w-9 h-9 rounded-lg flex items-center justify-center shrink-0"
                              style={{ backgroundColor: `${cat.colorHex}20` }}
                            >
                              {renderCategoryIcon(cat.icon, cat.colorHex)}
                            </div>
                            <div>
                              <div className="text-xs font-bold text-gray-900 dark:text-gray-100">{cat.nameArabic}</div>
                              <div className="text-[10px] text-gray-500 dark:text-gray-400 truncate max-w-[190px]">{cat.descriptionArabic}</div>
                            </div>
                          </div>
                          <div className="text-left shrink-0">
                            <div className="text-[11px] font-bold" style={{ color: cat.colorHex }}>
                              {exploredInCat}/{catQuestions.length}
                            </div>
                            <span className="text-[9px] text-gray-400">سؤالاً</span>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              </div>

              {/* Bottom Navigation */}
              <nav className="w-full bg-white dark:bg-[#162B26] border-t border-[#E7E1D5] dark:border-[#203D35] px-6 py-2.5 flex justify-between items-center text-xs text-gray-500 dark:text-gray-400 sticky bottom-0 z-10">
                <button
                  onClick={() => setCurrentScreen('home')}
                  className="flex flex-col items-center gap-1 font-bold text-[#176B5B] dark:text-[#32A790]"
                >
                  <Home size={18} />
                  <span>الرئيسية</span>
                </button>
                <button
                  onClick={() => {
                    soundManager.playCardClick();
                    setCurrentScreen('categories');
                  }}
                  className="flex flex-col items-center gap-1 hover:text-[#176B5B] transition"
                >
                  <Grid size={18} />
                  <span>المحاور</span>
                </button>
                <button
                  onClick={() => {
                    soundManager.playCardClick();
                    setCurrentScreen('session');
                  }}
                  className="flex flex-col items-center gap-1 hover:text-[#176B5B] transition"
                >
                  <Sparkles size={18} />
                  <span>جلسة خاصة</span>
                </button>
                <button
                  onClick={() => {
                    soundManager.playCardClick();
                    setCurrentScreen('favorites');
                  }}
                  className="flex flex-col items-center gap-1 hover:text-[#176B5B] transition"
                >
                  <Bookmark size={18} />
                  <span>المفضلة</span>
                </button>
                <button
                  onClick={() => {
                    soundManager.playCardClick();
                    setCurrentScreen('settings');
                  }}
                  className="flex flex-col items-center gap-1 hover:text-[#176B5B] transition"
                >
                  <Settings size={18} />
                  <span>الإعدادات</span>
                </button>
              </nav>
            </div>
          )}

          {/* SCREEN: CATEGORIES */}
          {currentScreen === 'categories' && (
            <div className="flex-1 flex flex-col justify-between overflow-y-auto">
              <div className="p-5">
                <div className="flex items-center gap-2 mb-4">
                  <button
                    onClick={() => setCurrentScreen('home')}
                    className="p-1.5 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-800 transition"
                  >
                    <ArrowRight size={18} />
                  </button>
                  <h3 className="text-lg font-bold">المحاور الحوارية الستة</h3>
                </div>

                <p className="text-xs text-gray-500 dark:text-gray-400 mb-4">
                  كل محور يحتوي على 30 سؤالاً مقسمة بالتساوي على 3 مستويات من التدرج والعمق.
                </p>

                <div className="space-y-3.5">
                  {MAWADDA_DATA.categories.map(cat => {
                    const catQuestions = MAWADDA_DATA.questions.filter(q => q.categoryId === cat.id);
                    const answeredCount = catQuestions.filter(q => exploredIds.includes(q.id)).length;
                    const pct = Math.round((answeredCount / catQuestions.length) * 100);

                    return (
                      <div
                        key={cat.id}
                        className="p-4 rounded-2xl bg-white dark:bg-[#162B26] border border-[#E7E1D5] dark:border-[#203D35] shadow-xs space-y-3"
                      >
                        <div className="flex items-start gap-3">
                          <div
                            className="w-11 h-11 rounded-xl flex items-center justify-center shrink-0"
                            style={{ backgroundColor: `${cat.colorHex}25` }}
                          >
                            {renderCategoryIcon(cat.icon, cat.colorHex)}
                          </div>
                          <div className="flex-1">
                            <div className="flex items-center justify-between">
                              <h4 className="font-bold text-sm text-gray-900 dark:text-gray-100">{cat.nameArabic}</h4>
                              <span className="text-xs font-bold" style={{ color: cat.colorHex }}>{answeredCount}/{catQuestions.length}</span>
                            </div>
                            <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5 leading-relaxed">
                              {cat.descriptionArabic}
                            </p>
                          </div>
                        </div>

                        {/* Progress Bar */}
                        <div className="w-full bg-gray-100 dark:bg-black/30 h-1.5 rounded-full overflow-hidden">
                          <div
                            className="h-full rounded-full transition-all duration-300"
                            style={{ width: `${pct}%`, backgroundColor: cat.colorHex }}
                          />
                        </div>

                        {/* Action buttons */}
                        <div className="flex gap-2 pt-1">
                          <button
                            onClick={() => startCategoryGame(cat.id, null)}
                            className="flex-1 py-2 rounded-xl text-xs font-bold text-white shadow-xs transition"
                            style={{ backgroundColor: cat.colorHex }}
                          >
                            بدء المحور كاملاً
                          </button>
                          <button
                            onClick={() => setLevelPickerCategory(cat)}
                            className="px-3 py-2 rounded-xl text-xs font-bold border border-gray-300 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-800 transition"
                          >
                            اختيار مستوى
                          </button>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* Back to Home Button */}
              <div className="p-4 border-t border-[#E7E1D5] dark:border-[#203D35] bg-white dark:bg-[#162B26]">
                <button
                  onClick={() => setCurrentScreen('home')}
                  className="w-full py-2.5 rounded-xl border border-gray-300 dark:border-gray-700 text-xs font-bold text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-800 transition"
                >
                  العودة للرئيسية
                </button>
              </div>
            </div>
          )}

          {/* SCREEN: GAME / QUESTION CARDS (Core experience) */}
          {currentScreen === 'game' && currentQ && (
            <div className="flex-1 flex flex-col justify-between p-5 overflow-hidden">
              {/* Header Bar with Category, Level, Favorite and Exit */}
              <div>
                <div className="flex justify-between items-center mb-2">
                  <button
                    onClick={() => {
                      soundManager.playCardClick();
                      setCurrentScreen('home');
                    }}
                    className="flex items-center gap-1 text-xs text-gray-500 hover:text-black dark:hover:text-white"
                  >
                    <ArrowRight size={16} />
                    <span>خروج</span>
                  </button>

                  <div className="flex items-center gap-1.5">
                    <span
                      className="px-2.5 py-0.5 rounded-full text-[11px] font-bold"
                      style={{ backgroundColor: `${currentCatColor}20`, color: currentCatColor }}
                    >
                      {currentQ.level === 1 ? 'مستوى 1: تعارف أولي' : (currentQ.level === 2 ? 'مستوى 2: فهم أعمق' : 'مستوى 3: مواقف وقرارات')}
                    </span>

                    <button
                      onClick={() => handleToggleFavorite(currentQ.id)}
                      className={`p-1.5 rounded-full border transition ${isCurrentFav ? 'bg-red-500/15 border-red-500 text-red-500' : 'border-gray-300 dark:border-gray-700 text-gray-400'}`}
                      title={isCurrentFav ? 'إزالة من المفضلة' : 'إضافة للمفضلة'}
                    >
                      <Bookmark size={16} className={isCurrentFav ? 'fill-current' : ''} />
                    </button>
                  </div>
                </div>

                {/* Progress bar */}
                <div className="flex justify-between text-[11px] text-gray-500 font-semibold mb-1">
                  <span>{currentCat?.nameArabic || 'جلسة حوارية'}</span>
                  <span>{gameIndex + 1} من {gameQuestions.length}</span>
                </div>
                <div className="w-full bg-gray-200 dark:bg-black/30 h-1.5 rounded-full overflow-hidden">
                  <div
                    className="h-full rounded-full transition-all duration-300"
                    style={{ width: `${((gameIndex + 1) / gameQuestions.length) * 100}%`, backgroundColor: currentCatColor }}
                  />
                </div>
              </div>

              {/* Big Question Card */}
              <div className="my-auto py-2">
                <AnimatePresence mode="wait">
                  <motion.div
                    key={currentQ.id}
                    initial={{ opacity: 0, scale: 0.95, y: 15 }}
                    animate={{ opacity: 1, scale: 1, y: 0 }}
                    exit={{ opacity: 0, scale: 0.95, y: -15 }}
                    transition={{ duration: 0.25 }}
                    className="w-full rounded-3xl p-6 bg-white dark:bg-[#162B26] border-2 shadow-xl flex flex-col justify-between min-h-[350px] relative overflow-hidden"
                    style={{ borderColor: `${currentCatColor}40` }}
                  >
                    {/* Background subtle Islamic floral watermark */}
                    <div className="absolute -top-12 -left-12 opacity-5 pointer-events-none">
                      <Heart size={200} />
                    </div>

                    {/* Top category pill */}
                    <div className="flex justify-center mb-3">
                      <div
                        className="px-3 py-1 rounded-full text-xs font-bold flex items-center gap-1.5 shadow-2xs"
                        style={{ backgroundColor: `${currentCatColor}15`, color: currentCatColor }}
                      >
                        <Heart size={13} className="fill-current" />
                        <span>{currentCat?.nameArabic || 'محور الحوار'}</span>
                      </div>
                    </div>

                    {/* Question text */}
                    <div className="my-auto text-center px-2">
                      <p className="text-xl sm:text-2xl font-bold leading-relaxed text-gray-900 dark:text-gray-100 font-['Tajawal']">
                        {currentQ.question}
                      </p>
                    </div>

                    {/* Follow-up question reveal */}
                    <div className="mt-4 pt-3 border-t border-gray-100 dark:border-gray-800">
                      {currentQ.followUp && !showFollowUp && (
                        <button
                          onClick={() => {
                            soundManager.playCardClick();
                            setShowFollowUp(true);
                          }}
                          className="w-full py-2 px-3 rounded-xl border border-dashed border-[#C8A96B] text-[#9E7B35] dark:text-[#DFC894] hover:bg-[#C8A96B]/10 transition text-xs font-bold flex items-center justify-center gap-1.5"
                        >
                          <HelpCircle size={15} />
                          <span>كشف السؤال الفرعي لتوسيع الحوار</span>
                        </button>
                      )}

                      {showFollowUp && (
                        <motion.div
                          initial={{ opacity: 0, y: 6 }}
                          animate={{ opacity: 1, y: 0 }}
                          className="bg-[#C8A96B]/15 dark:bg-[#C8A96B]/10 border border-[#C8A96B]/40 rounded-xl p-3 text-center"
                        >
                          <div className="text-[10px] font-bold text-[#9E7B35] dark:text-[#DFC894] mb-1 flex items-center justify-center gap-1">
                            <Sparkles size={12} />
                            <span>سؤال فرعي رديف للمناقشة:</span>
                          </div>
                          <p className="text-xs text-gray-800 dark:text-gray-200 leading-normal font-semibold">
                            {currentQ.followUp}
                          </p>
                        </motion.div>
                      )}

                      {/* Tags */}
                      <div className="flex flex-wrap justify-center gap-1 mt-3">
                        {currentQ.tags.map((t, idx) => (
                          <span key={idx} className="text-[10px] text-gray-400 bg-gray-100 dark:bg-black/20 px-2 py-0.5 rounded-full">
                            #{t}
                          </span>
                        ))}
                      </div>
                    </div>
                  </motion.div>
                </AnimatePresence>
              </div>

              {/* Controls bar: Previous, Skip, Next */}
              <div className="flex items-center justify-between gap-3 pt-2">
                <button
                  onClick={handlePrevQuestion}
                  disabled={gameIndex === 0}
                  className="p-3 rounded-2xl bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300 disabled:opacity-30 disabled:cursor-not-allowed hover:bg-gray-200 dark:hover:bg-gray-700 transition"
                  title="السؤال السابق"
                >
                  <ArrowRight size={20} />
                </button>

                <button
                  onClick={handleNextQuestion}
                  className="px-4 py-2.5 text-xs text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 transition font-semibold"
                >
                  تخطي السؤال
                </button>

                <button
                  onClick={handleNextQuestion}
                  className="flex-1 py-3 px-4 rounded-2xl text-white font-bold text-sm shadow-md transition flex items-center justify-center gap-2"
                  style={{ backgroundColor: currentCatColor }}
                >
                  <span>{gameIndex === gameQuestions.length - 1 ? 'إنهاء الجلسة' : 'السؤال التالي'}</span>
                  <ArrowLeft size={18} />
                </button>
              </div>
            </div>
          )}

          {/* SCREEN: CUSTOM SESSION CREATOR */}
          {currentScreen === 'session' && (
            <div className="flex-1 flex flex-col justify-between p-5 overflow-y-auto">
              <div className="space-y-4">
                <div className="flex items-center gap-2 mb-2">
                  <button
                    onClick={() => setCurrentScreen('home')}
                    className="p-1.5 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-800 transition"
                  >
                    <ArrowRight size={18} />
                  </button>
                  <h3 className="text-lg font-bold">تخصيص جلسة حوار</h3>
                </div>

                <div className="p-4 rounded-2xl bg-[#176B5B]/10 dark:bg-[#176B5B]/20 border border-[#176B5B]/30">
                  <h4 className="font-bold text-xs text-[#176B5B] dark:text-[#32A790] mb-1">صمم جلستك الحوارية</h4>
                  <p className="text-xs text-gray-600 dark:text-gray-300 leading-relaxed">
                    اختر المحاور التي ترغبان في استكشافها اليوم، وحدد مستوى العمق والعدد المناسب لوقتكما.
                  </p>
                </div>

                {/* Categories multi-selector */}
                <div>
                  <label className="text-xs font-bold text-gray-700 dark:text-gray-300 block mb-2">
                    المحاور المراد تضمينها:
                  </label>
                  <div className="grid grid-cols-2 gap-2">
                    {MAWADDA_DATA.categories.map(cat => {
                      const isSelected = selectedCats.includes(cat.id);
                      return (
                        <button
                          key={cat.id}
                          onClick={() => {
                            soundManager.playCardClick();
                            setSelectedCats(prev => {
                              if (prev.includes(cat.id)) {
                                if (prev.length > 1) return prev.filter(c => c !== cat.id);
                                return prev;
                              } else {
                                return [...prev, cat.id];
                              }
                            });
                          }}
                          className={`p-2.5 rounded-xl text-right border text-xs font-bold transition flex items-center justify-between ${isSelected ? 'bg-white dark:bg-[#162B26] border-[#176B5B] shadow-xs' : 'bg-gray-50 dark:bg-black/20 border-gray-200 dark:border-gray-800 opacity-60'}`}
                        >
                          <span style={{ color: isSelected ? cat.colorHex : undefined }}>{cat.nameArabic}</span>
                          {isSelected && <CheckCircle2 size={15} style={{ color: cat.colorHex }} />}
                        </button>
                      );
                    })}
                  </div>
                </div>

                {/* Level selector */}
                <div>
                  <label className="text-xs font-bold text-gray-700 dark:text-gray-300 block mb-2">
                    مستوى عمق الأسئلة:
                  </label>
                  <div className="grid grid-cols-4 gap-1.5">
                    {[
                      { level: null, label: 'الكل' },
                      { level: 1, label: 'مستوى 1' },
                      { level: 2, label: 'مستوى 2' },
                      { level: 3, label: 'مستوى 3' }
                    ].map((item, idx) => {
                      const isSelected = selectedLevel === item.level;
                      return (
                        <button
                          key={idx}
                          onClick={() => {
                            soundManager.playCardClick();
                            setSelectedLevel(item.level);
                          }}
                          className={`py-2 rounded-xl text-xs font-bold border transition ${isSelected ? 'bg-[#176B5B] text-white border-[#176B5B]' : 'bg-white dark:bg-[#162B26] border-gray-300 dark:border-gray-700 text-gray-700 dark:text-gray-300'}`}
                        >
                          {item.label}
                        </button>
                      );
                    })}
                  </div>
                </div>

                {/* Question count selector */}
                <div>
                  <label className="text-xs font-bold text-gray-700 dark:text-gray-300 block mb-2">
                    عدد بطاقات الجلسة:
                  </label>
                  <div className="grid grid-cols-4 gap-1.5">
                    {[10, 15, 20, 30].map(cnt => {
                      const isSelected = sessionCount === cnt;
                      return (
                        <button
                          key={cnt}
                          onClick={() => {
                            soundManager.playCardClick();
                            setSessionCount(cnt);
                          }}
                          className={`py-2 rounded-xl text-xs font-bold border transition ${isSelected ? 'bg-[#C8A96B] text-black border-[#C8A96B]' : 'bg-white dark:bg-[#162B26] border-gray-300 dark:border-gray-700 text-gray-700 dark:text-gray-300'}`}
                        >
                          {cnt} بطاقة
                        </button>
                      );
                    })}
                  </div>
                </div>
              </div>

              {/* Start Session Button */}
              <div className="pt-4">
                <button
                  onClick={startCustomSession}
                  className="w-full py-3.5 rounded-2xl bg-[#176B5B] hover:bg-[#12574A] text-white font-bold text-sm shadow-md transition flex items-center justify-center gap-2"
                >
                  <Play size={18} className="fill-current" />
                  <span>بدء الجلسة المخصصة</span>
                </button>
              </div>
            </div>
          )}

          {/* SCREEN: FAVORITES */}
          {currentScreen === 'favorites' && (
            <div className="flex-1 flex flex-col justify-between overflow-y-auto">
              <div className="p-5">
                <div className="flex items-center gap-2 mb-3">
                  <button
                    onClick={() => setCurrentScreen('home')}
                    className="p-1.5 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-800 transition"
                  >
                    <ArrowRight size={18} />
                  </button>
                  <h3 className="text-lg font-bold">الأسئلة المفضلة ({favorites.length})</h3>
                </div>

                {/* Category filter pills */}
                {favorites.length > 0 && (
                  <div className="flex gap-1.5 overflow-x-auto pb-2 mb-3 text-xs scrollbar-none">
                    <button
                      onClick={() => setFavCategoryFilter(null)}
                      className={`px-3 py-1 rounded-full shrink-0 font-bold transition ${favCategoryFilter === null ? 'bg-[#176B5B] text-white' : 'bg-gray-200 dark:bg-gray-800 text-gray-600 dark:text-gray-300'}`}
                    >
                      الكل ({favorites.length})
                    </button>
                    {MAWADDA_DATA.categories.map(cat => {
                      const countInCat = favorites.filter(id => {
                        const q = MAWADDA_DATA.questions.find(item => item.id === id);
                        return q?.categoryId === cat.id;
                      }).length;
                      if (countInCat === 0) return null;

                      return (
                        <button
                          key={cat.id}
                          onClick={() => setFavCategoryFilter(cat.id)}
                          className={`px-3 py-1 rounded-full shrink-0 font-bold transition ${favCategoryFilter === cat.id ? 'text-white' : 'bg-gray-200 dark:bg-gray-800 text-gray-600 dark:text-gray-300'}`}
                          style={{ backgroundColor: favCategoryFilter === cat.id ? cat.colorHex : undefined }}
                        >
                          {cat.nameArabic} ({countInCat})
                        </button>
                      );
                    })}
                  </div>
                )}

                {/* If empty */}
                {favorites.length === 0 ? (
                  <div className="py-20 text-center">
                    <div className="w-16 h-16 rounded-full bg-red-100 dark:bg-red-950/40 text-red-500 mx-auto flex items-center justify-center mb-3">
                      <Bookmark size={28} />
                    </div>
                    <h4 className="font-bold text-sm text-gray-700 dark:text-gray-300">لا توجد أسئلة محفوظة بعد</h4>
                    <p className="text-xs text-gray-400 mt-1 max-w-xs mx-auto">
                      أثناء تصفح البطاقات الحوارية، اضغط على أيقونة الإشارة المرجعية لحفظ السؤال للرجوع إليه لاحقاً.
                    </p>
                  </div>
                ) : (
                  <div className="space-y-3">
                    {/* Launch favorites session button */}
                    {(() => {
                      const filteredList = favorites
                        .map(id => MAWADDA_DATA.questions.find(q => q.id === id))
                        .filter((q): q is Question => q !== undefined)
                        .filter(q => (favCategoryFilter ? q.categoryId === favCategoryFilter : true));

                      return (
                        <button
                          onClick={() => startFavoritesSession(filteredList)}
                          className="w-full py-2.5 rounded-xl bg-[#C8A96B] hover:bg-[#B89656] text-black font-bold text-xs shadow-xs transition flex items-center justify-center gap-2 mb-2"
                        >
                          <Play size={14} className="fill-current" />
                          <span>بدء جلسة حوار بالأسئلة المفضلة ({filteredList.length})</span>
                        </button>
                      );
                    })()}

                    {/* Cards list */}
                    {favorites
                      .map(id => MAWADDA_DATA.questions.find(q => q.id === id))
                      .filter((q): q is Question => q !== undefined)
                      .filter(q => (favCategoryFilter ? q.categoryId === favCategoryFilter : true))
                      .map(q => {
                        const cat = MAWADDA_DATA.categories.find(c => c.id === q.categoryId);
                        return (
                          <div
                            key={q.id}
                            className="p-4 rounded-xl bg-white dark:bg-[#162B26] border border-[#E7E1D5] dark:border-[#203D35] shadow-2xs space-y-2 relative"
                          >
                            <div className="flex items-center justify-between">
                              <span
                                className="px-2 py-0.5 rounded text-[10px] font-bold"
                                style={{ backgroundColor: `${cat?.colorHex}20`, color: cat?.colorHex }}
                              >
                                {cat?.nameArabic} • {q.level === 1 ? 'مستوى 1' : (q.level === 2 ? 'مستوى 2' : 'مستوى 3')}
                              </span>

                              <button
                                onClick={() => handleToggleFavorite(q.id)}
                                className="text-red-500 hover:text-red-600 p-1"
                                title="إزالة من المفضلة"
                              >
                                <Bookmark size={16} className="fill-current" />
                              </button>
                            </div>

                            <p className="text-xs font-bold text-gray-900 dark:text-gray-100 leading-relaxed">
                              {q.question}
                            </p>

                            {q.followUp && (
                              <p className="text-[11px] text-gray-500 dark:text-gray-400 bg-gray-50 dark:bg-black/20 p-2 rounded-lg leading-normal">
                                <span className="font-bold text-[#C8A96B]">سؤال فرعي: </span>
                                {q.followUp}
                              </p>
                            )}
                          </div>
                        );
                      })}
                  </div>
                )}
              </div>

              {/* Bottom return */}
              <div className="p-4 border-t border-[#E7E1D5] dark:border-[#203D35] bg-white dark:bg-[#162B26]">
                <button
                  onClick={() => setCurrentScreen('home')}
                  className="w-full py-2.5 rounded-xl border border-gray-300 dark:border-gray-700 text-xs font-bold text-gray-700 dark:text-gray-300"
                >
                  العودة للرئيسية
                </button>
              </div>
            </div>
          )}

          {/* SCREEN: SETTINGS */}
          {currentScreen === 'settings' && (
            <div className="flex-1 flex flex-col justify-between overflow-y-auto">
              <div className="p-5 space-y-4">
                <div className="flex items-center gap-2 mb-2">
                  <button
                    onClick={() => setCurrentScreen('home')}
                    className="p-1.5 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-800 transition"
                  >
                    <ArrowRight size={18} />
                  </button>
                  <h3 className="text-lg font-bold">الإعدادات والضوابط</h3>
                </div>

                {/* Theme Selector */}
                <div className="p-4 rounded-2xl bg-white dark:bg-[#162B26] border border-[#E7E1D5] dark:border-[#203D35]">
                  <h4 className="text-xs font-bold text-gray-500 mb-2">المظهر والتصميم</h4>
                  <div className="grid grid-cols-2 gap-2">
                    <button
                      onClick={() => setTheme('light')}
                      className={`py-2 px-3 rounded-xl text-xs font-bold flex items-center justify-center gap-2 border transition ${theme === 'light' ? 'bg-[#176B5B] text-white border-[#176B5B]' : 'border-gray-300 dark:border-gray-700 text-gray-700 dark:text-gray-300'}`}
                    >
                      <Sun size={15} />
                      <span>الوضع النهاري</span>
                    </button>
                    <button
                      onClick={() => setTheme('dark')}
                      className={`py-2 px-3 rounded-xl text-xs font-bold flex items-center justify-center gap-2 border transition ${theme === 'dark' ? 'bg-[#176B5B] text-white border-[#176B5B]' : 'border-gray-300 dark:border-gray-700 text-gray-700 dark:text-gray-300'}`}
                    >
                      <Moon size={15} />
                      <span>الوضع الليلي</span>
                    </button>
                  </div>
                </div>

                {/* Islamic Content & Guidelines */}
                <div className="p-4 rounded-2xl bg-white dark:bg-[#162B26] border border-[#E7E1D5] dark:border-[#203D35] space-y-2">
                  <h4 className="text-xs font-bold text-gray-500 mb-1">المنهجية والمحتوى</h4>

                  <button
                    onClick={() => setShowIslamicGuidelines(true)}
                    className="w-full py-2.5 px-3 rounded-xl hover:bg-gray-50 dark:hover:bg-gray-800/50 flex items-center justify-between text-xs font-bold transition text-right"
                  >
                    <div className="flex items-center gap-2.5">
                      <BookOpen size={16} className="text-[#176B5B] dark:text-[#32A790]" />
                      <span>الضوابط والمنهجية الشرعية لمودة</span>
                    </div>
                    <ChevronLeft size={16} className="text-gray-400" />
                  </button>

                  <button
                    onClick={() => setShowPrivacyModal(true)}
                    className="w-full py-2.5 px-3 rounded-xl hover:bg-gray-50 dark:hover:bg-gray-800/50 flex items-center justify-between text-xs font-bold transition text-right"
                  >
                    <div className="flex items-center gap-2.5">
                      <Shield size={16} className="text-[#C8A96B]" />
                      <span>الخصوصية وأمان البيانات المحلية (Offline)</span>
                    </div>
                    <ChevronLeft size={16} className="text-gray-400" />
                  </button>

                  <button
                    onClick={() => setShowAboutModal(true)}
                    className="w-full py-2.5 px-3 rounded-xl hover:bg-gray-50 dark:hover:bg-gray-800/50 flex items-center justify-between text-xs font-bold transition text-right"
                  >
                    <div className="flex items-center gap-2.5">
                      <Info size={16} className="text-[#176B5B] dark:text-[#32A790]" />
                      <span>عن تطبيق مودة ورسالته</span>
                    </div>
                    <ChevronLeft size={16} className="text-gray-400" />
                  </button>
                </div>

                {/* Reset Actions */}
                <div className="p-4 rounded-2xl bg-white dark:bg-[#162B26] border border-[#E7E1D5] dark:border-[#203D35] space-y-2">
                  <h4 className="text-xs font-bold text-gray-500 mb-1">إدارة البيانات والمحفوظات</h4>

                  <button
                    onClick={resetProgress}
                    className="w-full py-2 px-3 rounded-xl hover:bg-red-50 dark:hover:bg-red-950/20 text-red-600 dark:text-red-400 flex items-center justify-between text-xs font-bold transition text-right"
                  >
                    <div className="flex items-center gap-2.5">
                      <RotateCcw size={15} />
                      <span>إعادة ضبط سجل الأسئلة المستكشفة</span>
                    </div>
                    <span className="text-[10px] bg-red-100 dark:bg-red-950/40 px-2 py-0.5 rounded">تصفير</span>
                  </button>

                  <button
                    onClick={resetOnboarding}
                    className="w-full py-2 px-3 rounded-xl hover:bg-gray-50 dark:hover:bg-gray-800/50 text-gray-700 dark:text-gray-300 flex items-center justify-between text-xs font-bold transition text-right"
                  >
                    <div className="flex items-center gap-2.5">
                      <Layers size={15} />
                      <span>إعادة عرض شاشات الترحيب والتعريف</span>
                    </div>
                  </button>
                </div>
              </div>

              {/* Bottom return */}
              <div className="p-4 border-t border-[#E7E1D5] dark:border-[#203D35] bg-white dark:bg-[#162B26]">
                <button
                  onClick={() => setCurrentScreen('home')}
                  className="w-full py-2.5 rounded-xl border border-gray-300 dark:border-gray-700 text-xs font-bold text-gray-700 dark:text-gray-300"
                >
                  العودة للرئيسية
                </button>
              </div>
            </div>
          )}

        </div>
      </main>

      {/* MODAL: LEVEL PICKER FOR CATEGORY */}
      <AnimatePresence>
        {levelPickerCategory && (
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-end sm:items-center justify-center p-4 z-50">
            <motion.div
              initial={{ opacity: 0, y: 50 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: 50 }}
              className="w-full max-w-sm rounded-3xl bg-[#FAF8F3] dark:bg-[#162B26] p-6 shadow-2xl border border-[#C8A96B]/40 space-y-4"
            >
              <div className="flex items-center justify-between border-b pb-3 border-gray-200 dark:border-gray-700">
                <h4 className="font-bold text-base text-gray-900 dark:text-gray-100">
                  اختر المستوى — {levelPickerCategory.nameArabic}
                </h4>
                <button
                  onClick={() => setLevelPickerCategory(null)}
                  className="text-gray-400 hover:text-black dark:hover:text-white"
                >
                  ✕
                </button>
              </div>

              <div className="space-y-2">
                <button
                  onClick={() => startCategoryGame(levelPickerCategory.id, 1)}
                  className="w-full p-3 rounded-xl bg-white dark:bg-[#0E1D19] border border-gray-200 dark:border-gray-800 hover:border-[#176B5B] transition text-right"
                >
                  <div className="text-xs font-bold text-[#176B5B] dark:text-[#32A790]">المستوى الأول: التعارف الأولي</div>
                  <div className="text-[11px] text-gray-500 mt-0.5">أسئلة مريحة وممهدة للنقاش (10 بطاقات)</div>
                </button>

                <button
                  onClick={() => startCategoryGame(levelPickerCategory.id, 2)}
                  className="w-full p-3 rounded-xl bg-white dark:bg-[#0E1D19] border border-gray-200 dark:border-gray-800 hover:border-[#C8A96B] transition text-right"
                >
                  <div className="text-xs font-bold text-[#C8A96B]">المستوى الثاني: فهم أعمق</div>
                  <div className="text-[11px] text-gray-500 mt-0.5">القيم والتطلعات وطريقة التفكير (10 بطاقات)</div>
                </button>

                <button
                  onClick={() => startCategoryGame(levelPickerCategory.id, 3)}
                  className="w-full p-3 rounded-xl bg-white dark:bg-[#0E1D19] border border-gray-200 dark:border-gray-800 hover:border-red-400 transition text-right"
                >
                  <div className="text-xs font-bold text-red-500">المستوى الثالث: مواقف وقرارات</div>
                  <div className="text-[11px] text-gray-500 mt-0.5">سيناريوهات واقعية وقرارات حاسمة (10 بطاقات)</div>
                </button>

                <button
                  onClick={() => startCategoryGame(levelPickerCategory.id, null)}
                  className="w-full py-2.5 rounded-xl bg-[#176B5B] text-white text-xs font-bold mt-2 shadow-xs"
                >
                  بدء المحور كاملاً (30 بطاقة بالتدرج)
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* MODAL: COMPLETION CELEBRATION */}
      <AnimatePresence>
        {showCompletionModal && (
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 z-50">
            <motion.div
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.9 }}
              className="w-full max-w-sm rounded-3xl bg-white dark:bg-[#162B26] p-6 shadow-2xl border-2 border-[#C8A96B] text-center space-y-4"
            >
              <div className="w-16 h-16 rounded-full bg-[#176B5B]/15 text-[#176B5B] dark:text-[#32A790] mx-auto flex items-center justify-center">
                <Sparkles size={32} />
              </div>
              <h3 className="text-xl font-bold text-[#176B5B] dark:text-[#32A790]">
                أحسنتما! بارك الله في مسعاكما
              </h3>
              <p className="text-xs text-gray-600 dark:text-gray-300 leading-relaxed">
                لقد أتممتما استكشاف هذه المجموعة من البطاقات الحوارية. نسأل الله أن يبارك في هذا الحوار الواعي ويجعله خطوة خير ومودة وسكينة نحو بيت مسلم مستقر.
              </p>
              <button
                onClick={() => {
                  soundManager.playCardClick();
                  setShowCompletionModal(false);
                  setCurrentScreen('home');
                }}
                className="w-full py-3 rounded-xl bg-[#176B5B] text-white font-bold text-xs shadow-md transition"
              >
                العودة للرئيسية
              </button>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* MODAL: ISLAMIC CONTENT GUIDELINES */}
      <AnimatePresence>
        {showIslamicGuidelines && (
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 z-50">
            <motion.div
              initial={{ opacity: 0, y: 30 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: 30 }}
              className="w-full max-w-md max-h-[85vh] rounded-3xl bg-white dark:bg-[#162B26] p-6 shadow-2xl border border-[#C8A96B]/50 flex flex-col"
            >
              <div className="flex items-center justify-between pb-3 border-b border-gray-200 dark:border-gray-700">
                <div className="flex items-center gap-2">
                  <BookOpen size={18} className="text-[#176B5B] dark:text-[#32A790]" />
                  <h4 className="font-bold text-sm">الضوابط والمنهجية الشرعية لمودة</h4>
                </div>
                <button onClick={() => setShowIslamicGuidelines(false)} className="text-gray-400 hover:text-black">✕</button>
              </div>

              <div className="overflow-y-auto py-3 space-y-3 text-xs leading-relaxed text-gray-700 dark:text-gray-300">
                <p className="font-bold text-[#176B5B] dark:text-[#32A790]">
                  بنيت جميع أسئلة مودة (180 سؤالاً) وفق خمسة معايير شرعية رصينة:
                </p>
                <div className="space-y-2">
                  <div className="p-2.5 rounded-xl bg-[#FAF8F3] dark:bg-black/20 border border-gray-200 dark:border-gray-800">
                    <span className="font-bold block text-gray-900 dark:text-gray-100">١. العفة وصون الحياء:</span>
                    تخلو الأسئلة تماماً من أي إيحاءات تخدش الحياء، وتصب في مكارم الأخلاق والمسؤوليات الزوجية.
                  </div>
                  <div className="p-2.5 rounded-xl bg-[#FAF8F3] dark:bg-black/20 border border-gray-200 dark:border-gray-800">
                    <span className="font-bold block text-gray-900 dark:text-gray-100">٢. ستر العورات وحظر التفتيش في الماضي:</span>
                    لا يتضمن التطبيق أي سؤال يستدعي كشف ذنوب ماضية أو خصوصيات منهي عن كشفها شرعاً.
                  </div>
                  <div className="p-2.5 rounded-xl bg-[#FAF8F3] dark:bg-black/20 border border-gray-200 dark:border-gray-800">
                    <span className="font-bold block text-gray-900 dark:text-gray-100">٣. دعم البيئة الأسرية:</span>
                    أداة مساعدة في مجالس التعارف الأسرية بحضور الأهل والمحارم دون خلوة غير مشروعة.
                  </div>
                  <div className="p-2.5 rounded-xl bg-[#FAF8F3] dark:bg-black/20 border border-gray-200 dark:border-gray-800">
                    <span className="font-bold block text-gray-900 dark:text-gray-100">٤. الأمانة العلمية:</span>
                    خلو التطبيق من أي نصوص أو أحاديث موضوعة، والاستناد للمقاصد الإسلامية العامة في المودة والرحمة.
                  </div>
                  <div className="p-2.5 rounded-xl bg-[#FAF8F3] dark:bg-black/20 border border-gray-200 dark:border-gray-800">
                    <span className="font-bold block text-gray-900 dark:text-gray-100">٥. نفي التنبؤ أو الكهانة:</span>
                    التطبيق ليس أداة حتمية تدعي التنبؤ بالغيب أو الجزم بنجاح الزواج؛ بل وسيلة حوار واستبانة.
                  </div>
                </div>
              </div>

              <button
                onClick={() => setShowIslamicGuidelines(false)}
                className="w-full py-2.5 rounded-xl bg-[#176B5B] text-white text-xs font-bold mt-2"
              >
                فهمت ذلك
              </button>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* MODAL: PRIVACY POLICY */}
      <AnimatePresence>
        {showPrivacyModal && (
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 z-50">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-sm rounded-3xl bg-white dark:bg-[#162B26] p-6 shadow-2xl border border-gray-200 dark:border-gray-700 space-y-3"
            >
              <div className="flex items-center justify-between pb-2 border-b border-gray-200 dark:border-gray-700">
                <h4 className="font-bold text-sm">سياسة الخصوصية وأمان البيانات</h4>
                <button onClick={() => setShowPrivacyModal(false)} className="text-gray-400">✕</button>
              </div>
              <div className="text-xs text-gray-600 dark:text-gray-300 space-y-2 leading-relaxed">
                <p>• التطبيق يعمل بالكامل دون حاجة للاتصال بالإنترنت (Offline 100%).</p>
                <p>• لا يتطلب إنشاء حساب أو تسجيل دخول أو إدخال أسماء أو أرقام هواتف إطلاقاً.</p>
                <p>• تُحفظ بياناتك (المفضلة، سجل التقدم، تفضيلات المظهر) محلياً فقط على جهازك.</p>
                <p>• لا توجد أي أدوات تتبع أو إعلانات تجارية أو خوادم تجمع بياناتك.</p>
              </div>
              <button
                onClick={() => setShowPrivacyModal(false)}
                className="w-full py-2.5 rounded-xl bg-[#176B5B] text-white text-xs font-bold"
              >
                إغلاق
              </button>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* MODAL: ABOUT MAWADDA */}
      <AnimatePresence>
        {showAboutModal && (
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 z-50">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-sm rounded-3xl bg-white dark:bg-[#162B26] p-6 shadow-2xl border border-gray-200 dark:border-gray-700 text-center space-y-3"
            >
              <div className="w-12 h-12 rounded-full bg-[#176B5B] text-[#C8A96B] font-bold text-2xl mx-auto flex items-center justify-center">
                م
              </div>
              <h4 className="font-bold text-base text-[#176B5B] dark:text-[#32A790]">مودة (Mawadda) — الإصدار 1.0.0</h4>
              <p className="text-xs text-gray-600 dark:text-gray-300 leading-relaxed">
                تطبيق بطاقات حوارية إسلامية هادفة للتعارف قبل الزواج بضوابط شرعية وقيم إسلامية راقية.
              </p>
              <div className="text-[11px] text-gray-400">
                180 سؤالاً أصيلاً عبر 6 محاور و 3 مستويات تعمق.
              </div>
              <button
                onClick={() => setShowAboutModal(false)}
                className="w-full py-2.5 rounded-xl bg-[#176B5B] text-white text-xs font-bold"
              >
                إغلاق
              </button>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* MODAL: FLUTTER PROJECT & APK CI EXPLORER DRAWER */}
      <AnimatePresence>
        {showFlutterDrawer && (
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 z-50">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-2xl max-h-[90vh] rounded-3xl bg-white dark:bg-[#12221E] p-6 shadow-2xl border border-[#C8A96B]/50 flex flex-col"
            >
              <div className="flex items-center justify-between pb-3 border-b border-gray-200 dark:border-gray-700">
                <div className="flex items-center gap-2">
                  <FileCode size={20} className="text-[#C8A96B]" />
                  <h3 className="font-bold text-sm sm:text-base">مشروع Flutter وملف بناء APK أندرويد</h3>
                </div>
                <button onClick={() => setShowFlutterDrawer(false)} className="text-gray-400 hover:text-black">✕</button>
              </div>

              <div className="overflow-y-auto py-3 space-y-4 text-xs leading-relaxed">
                {/* Summary banner */}
                <div className="p-3.5 rounded-xl bg-[#176B5B]/10 dark:bg-[#176B5B]/20 border border-[#176B5B]/30 flex items-start gap-2.5">
                  <CheckCircle2 size={18} className="text-[#176B5B] dark:text-[#32A790] shrink-0 mt-0.5" />
                  <div>
                    <h5 className="font-bold text-[#176B5B] dark:text-[#32A790]">مشروع Flutter متكامل في مساحة العمل</h5>
                    <p className="text-gray-600 dark:text-gray-300 text-[11px] mt-0.5">
                      تم إنشاء هيكل مشروع Flutter بالكامل (`lib/`, `android/`, `test/`, `assets/`, `pubspec.yaml`, `analysis_options.yaml`) بمعمارية Feature-First و Material 3 مع دعم كامل للـ RTL.
                    </p>
                  </div>
                </div>

                {/* Direct Download ZIP for Flutter Project */}
                <div className="p-4 rounded-xl bg-gradient-to-r from-[#176B5B]/15 to-[#C8A96B]/15 border border-[#176B5B]/30 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3">
                  <div>
                    <h5 className="font-bold text-sm text-[#176B5B] dark:text-[#32A790] flex items-center gap-1.5">
                      <Download size={16} />
                      <span>تنزيل حزمة كود Flutter كاملة (ZIP)</span>
                    </h5>
                    <p className="text-[11px] text-gray-600 dark:text-gray-300 mt-0.5">
                      يحتوي على كافة ملفات المشروع: Dart، وAndroid Gradle، و180 سؤالاً، والاختبارات، وسير عمل الـ APK.
                    </p>
                  </div>
                  <a
                    href="/mawadda_flutter_project.zip"
                    download="mawadda_flutter_project.zip"
                    className="px-4 py-2 rounded-xl bg-[#176B5B] text-white font-bold text-xs hover:bg-[#12574A] transition flex items-center gap-2 shadow-sm shrink-0"
                  >
                    <Download size={15} />
                    <span>تحميل المشروع (.zip)</span>
                  </a>
                </div>

                {/* GitHub Actions CI details */}
                <div className="border border-gray-200 dark:border-gray-800 rounded-xl p-3.5 space-y-2 bg-gray-50 dark:bg-black/20">
                  <div className="flex items-center justify-between">
                    <span className="font-bold text-gray-900 dark:text-gray-100 flex items-center gap-1.5">
                      <Sparkles size={14} className="text-[#C8A96B]" />
                      سير عمل GitHub Actions المؤتمت: `.github/workflows/android-apk.yml`
                    </span>
                    <button
                      onClick={copyWorkflowYaml}
                      className="flex items-center gap-1 px-2.5 py-1 rounded bg-[#176B5B] text-white text-[11px] font-bold hover:bg-[#12574A] transition"
                    >
                      {copiedWorkflow ? <Check size={12} /> : <Copy size={12} />}
                      <span>{copiedWorkflow ? 'تم النسخ!' : 'نسخ سير العمل'}</span>
                    </button>
                  </div>
                  <p className="text-[11px] text-gray-500">
                    يعمل السير تلقائياً على خوادم GitHub (Ubuntu + Java 17 + Flutter) لبناء ملف الـ APK ورفعه كـ Artifact جاهز للتحميل مجاناً بضغطة زر دون الحاجة لتثبيت أي برامج على جهازك.
                  </p>
                </div>

                {/* Local build commands */}
                <div className="border border-gray-200 dark:border-gray-800 rounded-xl p-3.5 space-y-2 bg-gray-50 dark:bg-black/20">
                  <span className="font-bold text-gray-900 dark:text-gray-100 block">
                    أوامر البناء المحلي في Flutter:
                  </span>
                  <div className="bg-black/80 text-emerald-400 p-2.5 rounded-lg font-mono text-[11px] dir-ltr text-left overflow-x-auto">
                    flutter pub get<br />
                    dart format --output=none --set-exit-if-changed .<br />
                    flutter analyze<br />
                    flutter test<br />
                    flutter build apk --release
                  </div>
                </div>

                {/* Download questions dataset */}
                <div className="flex justify-between items-center p-3 rounded-xl border border-gray-200 dark:border-gray-800">
                  <div>
                    <span className="font-bold block text-gray-900 dark:text-gray-100">قاعدة بيانات الأسئلة (180 سؤالاً كاملاً)</span>
                    <span className="text-[11px] text-gray-500">مخزنة في `assets/questions/questions.json`</span>
                  </div>
                  <button
                    onClick={downloadQuestionsJson}
                    className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#C8A96B] text-black font-bold text-xs hover:bg-[#B89656] transition"
                  >
                    <Download size={14} />
                    <span>تنزيل questions.json</span>
                  </button>
                </div>
              </div>

              <button
                onClick={() => setShowFlutterDrawer(false)}
                className="w-full py-2.5 rounded-xl bg-gray-200 dark:bg-gray-800 text-gray-800 dark:text-gray-200 text-xs font-bold mt-2 hover:bg-gray-300 transition"
              >
                إغلاق
              </button>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* MODAL: DIRECT INSTALL ON PHONE GUIDE */}
      <AnimatePresence>
        {showInstallModal && (
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 z-50">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-md rounded-3xl bg-white dark:bg-[#162B26] p-6 shadow-2xl border-2 border-[#176B5B] flex flex-col space-y-4"
            >
              <div className="flex items-center justify-between pb-2 border-b border-gray-200 dark:border-gray-700">
                <div className="flex items-center gap-2">
                  <Smartphone size={22} className="text-[#176B5B] dark:text-[#32A790]" />
                  <h3 className="font-bold text-base">تثبيت مودة على هاتفك فوراً</h3>
                </div>
                <button onClick={() => setShowInstallModal(false)} className="text-gray-400 hover:text-black">✕</button>
              </div>

              <div className="space-y-3 text-xs leading-relaxed text-gray-700 dark:text-gray-300">
                <div className="p-3 rounded-xl bg-[#176B5B]/10 dark:bg-[#176B5B]/20 border border-[#176B5B]/30">
                  <span className="font-bold text-[#176B5B] dark:text-[#32A790] block mb-1">
                    لماذا لا تحتاج للانتظار أو تثبيت ملف APK يدوي؟
                  </span>
                  <p className="text-[11px] text-gray-600 dark:text-gray-300">
                    تطبيق مودة مجهز كـ <strong>تطبيق ويب تقدمي (PWA) معتمد</strong>، مما يتيح لك تثبيته مباشرة على هاتفك الأندرويد في ثوانٍ معدودة دون الحاجة لتفعيل وضع المطورين أو خوض تعقيدات تثبيت ملفات APK الخارجية!
                  </p>
                </div>

                {/* If browser supports beforeinstallprompt */}
                {isInstallable && (
                  <button
                    onClick={() => {
                      installPWA();
                      setShowInstallModal(false);
                    }}
                    className="w-full py-3 rounded-xl bg-[#176B5B] hover:bg-[#12574A] text-white font-bold text-xs shadow-md transition flex items-center justify-center gap-2"
                  >
                    <Download size={16} />
                    <span>تثبيت التطبيق الآن على هذا الجهاز</span>
                  </button>
                )}

                {/* Steps to install on Android phone */}
                <div className="space-y-2 bg-gray-50 dark:bg-black/20 p-3.5 rounded-xl border border-gray-200 dark:border-gray-800">
                  <span className="font-bold text-gray-900 dark:text-gray-100 block">
                    خطوات التثبيت على هاتف أندرويد:
                  </span>
                  <div className="flex items-start gap-2">
                    <span className="w-5 h-5 rounded-full bg-[#176B5B] text-white flex items-center justify-center text-[10px] font-bold shrink-0 mt-0.5">1</span>
                    <p>افتح هذا الرابط في متصفح Chrome على هاتفك:</p>
                  </div>
                  <div className="bg-white dark:bg-[#0E1D19] p-2 rounded-lg border border-gray-200 dark:border-gray-700 font-mono text-[10px] dir-ltr text-left flex items-center justify-between">
                    <span className="truncate pr-2">https://ais-pre-xuektrt42goqrilycvijtk-339395904675.europe-west2.run.app</span>
                    <button
                      onClick={() => {
                        navigator.clipboard.writeText('https://ais-pre-xuektrt42goqrilycvijtk-339395904675.europe-west2.run.app');
                        alert('تم نسخ الرابط! أرسله لهاتفك وافتحه في Chrome');
                      }}
                      className="px-2 py-1 bg-gray-100 dark:bg-gray-800 rounded text-gray-700 dark:text-gray-300 font-sans text-[10px] shrink-0 hover:bg-gray-200"
                    >
                      نسخ
                    </button>
                  </div>

                  <div className="flex items-start gap-2 pt-1">
                    <span className="w-5 h-5 rounded-full bg-[#176B5B] text-white flex items-center justify-center text-[10px] font-bold shrink-0 mt-0.5">2</span>
                    <p>اضغط على خيارات المتصفح <strong>(⋮)</strong> في أعلى الشاشة واختر <strong>"تثبيت التطبيق"</strong> أو <strong>"إضافة إلى الشاشة الرئيسية" (Install App)</strong>.</p>
                  </div>

                  <div className="flex items-start gap-2 pt-1">
                    <span className="w-5 h-5 rounded-full bg-[#C8A96B] text-black flex items-center justify-center text-[10px] font-bold shrink-0 mt-0.5">✓</span>
                    <p className="text-[#176B5B] dark:text-[#32A790] font-bold">سينزل التطبيق فوراً على شاشة هاتفك مع أيقونة مودة وشاشة البداية، ويعمل 100% دون إنترنت!</p>
                  </div>
                </div>

                {/* For iPhone users */}
                {isIOS && (
                  <div className="p-2.5 rounded-lg bg-amber-50 dark:bg-amber-950/20 text-amber-800 dark:text-amber-300 border border-amber-200 text-[11px]">
                    <strong>لمستخدمي iPhone:</strong> اضغط على زر المشاركة (Share) في Safari ثم اختر <strong>"إضافة إلى الشاشة الرئيسية" (Add to Home Screen)</strong>.
                  </div>
                )}
              </div>

              <button
                onClick={() => setShowInstallModal(false)}
                className="w-full py-2.5 rounded-xl bg-gray-200 dark:bg-gray-800 text-gray-800 dark:text-gray-200 text-xs font-bold transition"
              >
                إغلاق
              </button>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

    </div>
  );
}
