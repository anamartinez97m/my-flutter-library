import 'package:flutter/material.dart';
import 'package:mylibrary/screens/add_book.dart';
import 'package:mylibrary/screens/home.dart';
import 'package:mylibrary/screens/random.dart';
import 'package:mylibrary/screens/settings.dart';
import 'package:mylibrary/screens/statistics.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _selectedIndex = 0;

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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('My Library'),
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
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.cottage_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.donut_large_outlined),
            label: 'Statistics/Facts',
          ),
          NavigationDestination(icon: Icon(Icons.add_outlined), label: 'Add'),
          NavigationDestination(
            icon: Icon(Icons.shuffle_outlined),
            label: 'Random',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
