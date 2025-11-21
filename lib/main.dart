import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/providers/locale_provider.dart';
import 'package:myrandomlibrary/providers/theme_provider.dart';
import 'package:myrandomlibrary/screens/navigation.dart';
import 'package:myrandomlibrary/services/notification_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.requestPermissions();
  } catch (e) {
    debugPrint('Error initializing notifications: $e');
  }
  
  try {
    final bookProvider = await BookProvider.create();
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BookProvider>.value(value: bookProvider),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
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

    return MaterialApp(
      title: 'My Random Library',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('es')],
      locale: localeProvider.locale,
      theme: themeProvider.lightTheme.copyWith(
        textTheme: themeProvider.lightTheme.textTheme.copyWith(
          headlineLarge: themeProvider.lightTheme.textTheme.headlineLarge
              ?.copyWith(fontSize: 24),
          headlineMedium: themeProvider.lightTheme.textTheme.headlineMedium
              ?.copyWith(fontSize: 20),
          headlineSmall: themeProvider.lightTheme.textTheme.headlineSmall
              ?.copyWith(fontSize: 18),
          titleLarge: themeProvider.lightTheme.textTheme.titleLarge?.copyWith(
            fontSize: 18,
          ),
          titleMedium: themeProvider.lightTheme.textTheme.titleMedium?.copyWith(
            fontSize: 16,
          ),
          titleSmall: themeProvider.lightTheme.textTheme.titleSmall?.copyWith(
            fontSize: 14,
          ),
          bodyLarge: themeProvider.lightTheme.textTheme.bodyLarge?.copyWith(
            fontSize: 14,
          ),
          bodyMedium: themeProvider.lightTheme.textTheme.bodyMedium?.copyWith(
            fontSize: 13,
          ),
          bodySmall: themeProvider.lightTheme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
          ),
        ),
      ),
      darkTheme: themeProvider.darkTheme.copyWith(
        textTheme: themeProvider.darkTheme.textTheme.copyWith(
          headlineLarge: themeProvider.darkTheme.textTheme.headlineLarge
              ?.copyWith(fontSize: 24),
          headlineMedium: themeProvider.darkTheme.textTheme.headlineMedium
              ?.copyWith(fontSize: 20),
          headlineSmall: themeProvider.darkTheme.textTheme.headlineSmall
              ?.copyWith(fontSize: 18),
          titleLarge: themeProvider.darkTheme.textTheme.titleLarge?.copyWith(
            fontSize: 18,
          ),
          titleMedium: themeProvider.darkTheme.textTheme.titleMedium?.copyWith(
            fontSize: 16,
          ),
          titleSmall: themeProvider.darkTheme.textTheme.titleSmall?.copyWith(
            fontSize: 14,
          ),
          bodyLarge: themeProvider.darkTheme.textTheme.bodyLarge?.copyWith(
            fontSize: 14,
          ),
          bodyMedium: themeProvider.darkTheme.textTheme.bodyMedium?.copyWith(
            fontSize: 13,
          ),
          bodySmall: themeProvider.darkTheme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
          ),
        ),
      ),
      themeMode:
          themeProvider.themeMode == AppThemeMode.light
              ? ThemeMode.light
              : themeProvider.themeMode == AppThemeMode.dark
              ? ThemeMode.dark
              : ThemeMode.system,
      home: const NavigationScreen(),
    );
  }
}
