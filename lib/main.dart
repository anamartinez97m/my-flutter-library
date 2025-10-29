import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/providers/locale_provider.dart';
import 'package:myrandomlibrary/providers/theme_provider.dart';
import 'package:myrandomlibrary/screens/navigation.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    runApp(const MyApp());
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
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
      ],
      locale: localeProvider.locale,
      theme: themeProvider.lightTheme.copyWith(
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 28),
          headlineMedium: TextStyle(fontSize: 24),
          headlineSmall: TextStyle(fontSize: 20),
          titleLarge: TextStyle(fontSize: 18),
          titleMedium: TextStyle(fontSize: 16),
          titleSmall: TextStyle(fontSize: 14),
          bodyLarge: TextStyle(fontSize: 14),
          bodyMedium: TextStyle(fontSize: 13),
          bodySmall: TextStyle(fontSize: 12),
        ),
      ),
      darkTheme: themeProvider.darkTheme.copyWith(
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 28),
          headlineMedium: TextStyle(fontSize: 24),
          headlineSmall: TextStyle(fontSize: 20),
          titleLarge: TextStyle(fontSize: 18),
          titleMedium: TextStyle(fontSize: 16),
          titleSmall: TextStyle(fontSize: 14),
          bodyLarge: TextStyle(fontSize: 14),
          bodyMedium: TextStyle(fontSize: 13),
          bodySmall: TextStyle(fontSize: 12),
        ),
      ),
      themeMode: themeProvider.themeMode == AppThemeMode.light
          ? ThemeMode.light
          : themeProvider.themeMode == AppThemeMode.dark
              ? ThemeMode.dark
              : ThemeMode.system,
      home: const NavigationScreen(),
    );
  }
}
