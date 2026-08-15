import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/providers/feature_flag_provider.dart';
import 'package:myrandomlibrary/providers/locale_provider.dart';
import 'package:myrandomlibrary/providers/theme_provider.dart';
import 'package:myrandomlibrary/screens/get_started_screen.dart';
import 'package:myrandomlibrary/screens/navigation.dart';
import 'package:myrandomlibrary/screens/new_ui/new_navigation_screen.dart';
import 'package:myrandomlibrary/services/backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myrandomlibrary/services/google_auth_service.dart';
import 'package:myrandomlibrary/services/notification_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    );
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
  }

  // Initialize notification service
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.requestPermissions();
    // Reschedule reading reminders (in case books changed, app updated, or device rebooted)
    await notificationService.scheduleReadingReminders();
  } catch (e) {
    debugPrint('Error initializing notifications: $e');
  }

  // Auto backup is triggered after the app is fully loaded (see _AutoBackupRunner)

  try {
    final bookProvider = await BookProvider.create();
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BookProvider>.value(value: bookProvider),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider(create: (_) => FeatureFlagProvider()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint('❌ Error al crear BookProvider: $e');
    debugPrint('$stack');
    // Even in error case, provide ThemeProvider and LocaleProvider
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider(create: (_) => FeatureFlagProvider()),
        ],
        child: const MyApp(),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final flags = Provider.of<FeatureFlagProvider>(context);
    final isV2 = flags.newUiEnabled;

    const v2Overlay = SystemUiOverlayStyle(
      statusBarColor: Color(0xFFFDF8F6),
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    );

    final lightBase = themeProvider.lightTheme;
    final darkBase = themeProvider.darkTheme;
    final lightTheme =
        isV2
            ? lightBase.copyWith(
              appBarTheme: lightBase.appBarTheme.copyWith(
                systemOverlayStyle: v2Overlay,
              ),
            )
            : lightBase;
    final darkTheme =
        isV2
            ? darkBase.copyWith(
              appBarTheme: darkBase.appBarTheme.copyWith(
                systemOverlayStyle: v2Overlay,
              ),
            )
            : darkBase;

    Widget app = MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      title: 'My Book Vault',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('es')],
      locale: localeProvider.locale,
      theme: lightTheme.copyWith(
        textTheme: lightTheme.textTheme.copyWith(
          headlineLarge: lightTheme.textTheme.headlineLarge?.copyWith(
            fontSize: 24,
          ),
          headlineMedium: lightTheme.textTheme.headlineMedium?.copyWith(
            fontSize: 20,
          ),
          headlineSmall: lightTheme.textTheme.headlineSmall?.copyWith(
            fontSize: 18,
          ),
          titleLarge: lightTheme.textTheme.titleLarge?.copyWith(fontSize: 18),
          titleMedium: lightTheme.textTheme.titleMedium?.copyWith(fontSize: 16),
          titleSmall: lightTheme.textTheme.titleSmall?.copyWith(fontSize: 14),
          bodyLarge: lightTheme.textTheme.bodyLarge?.copyWith(fontSize: 14),
          bodyMedium: lightTheme.textTheme.bodyMedium?.copyWith(fontSize: 13),
          bodySmall: lightTheme.textTheme.bodySmall?.copyWith(fontSize: 12),
        ),
      ),
      darkTheme: darkTheme.copyWith(
        textTheme: darkTheme.textTheme.copyWith(
          headlineLarge: darkTheme.textTheme.headlineLarge?.copyWith(
            fontSize: 24,
          ),
          headlineMedium: darkTheme.textTheme.headlineMedium?.copyWith(
            fontSize: 20,
          ),
          headlineSmall: darkTheme.textTheme.headlineSmall?.copyWith(
            fontSize: 18,
          ),
          titleLarge: darkTheme.textTheme.titleLarge?.copyWith(fontSize: 18),
          titleMedium: darkTheme.textTheme.titleMedium?.copyWith(fontSize: 16),
          titleSmall: darkTheme.textTheme.titleSmall?.copyWith(fontSize: 14),
          bodyLarge: darkTheme.textTheme.bodyLarge?.copyWith(fontSize: 14),
          bodyMedium: darkTheme.textTheme.bodyMedium?.copyWith(fontSize: 13),
          bodySmall: darkTheme.textTheme.bodySmall?.copyWith(fontSize: 12),
        ),
      ),
      themeMode:
          themeProvider.themeMode == AppThemeMode.light
              ? ThemeMode.light
              : themeProvider.themeMode == AppThemeMode.dark
              ? ThemeMode.dark
              : ThemeMode.system,
      home: const _AutoBackupRunner(),
    );

    if (isV2) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: v2Overlay,
        child: app,
      );
    }
    return app;
  }
}

/// Wrapper widget that triggers auto backup in the background after the
/// first frame, then displays the regular NavigationScreen.
class _AutoBackupRunner extends StatefulWidget {
  const _AutoBackupRunner();

  @override
  State<_AutoBackupRunner> createState() => _AutoBackupRunnerState();
}

class _AutoBackupRunnerState extends State<_AutoBackupRunner> {
  bool? _hasSeenOnboarding;

  static const String _onboardingKey = 'has_seen_onboarding';

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.setReadingReminderTitleBuilder(
        (bookTitle) =>
            AppLocalizations.of(context)!.have_you_read_today_book(bookTitle),
      );
      _runAutoBackup();
      NotificationService().processPendingNavigation();
    });
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_onboardingKey) ?? false;
    if (mounted) {
      setState(() => _hasSeenOnboarding = seen);
    }
  }

  Future<void> _runAutoBackup() async {
    try {
      // Give Firebase App Check time to fully initialize its token
      await Future.delayed(const Duration(seconds: 5));
      final user = GoogleAuthService.instance.currentUser;
      // uid can be null — local backup will still run
      await BackupService.instance.performAutoBackupIfNeeded(user?.uid);
    } catch (e) {
      debugPrint('Error triggering auto backup: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasSeenOnboarding == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_hasSeenOnboarding!) {
      return const GetStartedScreen();
    }
    final flags = Provider.of<FeatureFlagProvider>(context);
    if (flags.newUiEnabled) {
      return const NewNavigationScreen();
    }
    return const NavigationScreen();
  }
}
