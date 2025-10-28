import 'package:flutter/material.dart';
import 'package:mylibrary/providers/book_provider.dart';
import 'package:mylibrary/screens/navigation.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final bookProvider = await BookProvider.create();
    runApp(
      ChangeNotifierProvider<BookProvider>.value(
        value: bookProvider,
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
    return MaterialApp(
      title: 'My Library',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
      home: const NavigationScreen(),
    );
  }
}
