import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/screens/add_book.dart';
import 'package:myrandomlibrary/screens/home.dart';
import 'package:myrandomlibrary/screens/random.dart';
import 'package:myrandomlibrary/screens/settings.dart';
import 'package:myrandomlibrary/screens/statistics.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
  
  static _NavigationScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<_NavigationScreenState>();
  }
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _selectedIndex = 0;
  
  void switchToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> widgetOptions = const [
    HomeScreen(),
    StatisticsScreen(),
    AddBookScreen(),
    RandomScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.app_title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: widgetOptions.elementAt(_selectedIndex),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        indicatorColor: Theme.of(context).navigationBarTheme.indicatorColor,
        selectedIndex: _selectedIndex,
        destinations: <Widget>[
          NavigationDestination(
            icon: const Icon(Icons.cottage_outlined),
            label: AppLocalizations.of(context)!.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.donut_large_outlined),
            label: AppLocalizations.of(context)!.statistics,
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_outlined),
            label: AppLocalizations.of(context)!.add_book,
          ),
          NavigationDestination(
            icon: const Icon(Icons.shuffle_outlined),
            label: AppLocalizations.of(context)!.random,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            label: AppLocalizations.of(context)!.settings,
          ),
        ],
      ),
    );
  }
}
