import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/screens/home.dart';
import 'package:myrandomlibrary/screens/my_books.dart';
import 'package:myrandomlibrary/screens/random.dart';
import 'package:myrandomlibrary/screens/settings.dart';
import 'package:myrandomlibrary/screens/statistics.dart';
import 'package:myrandomlibrary/services/app_update_service.dart';

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
  VoidCallback? _clearHomeSearch;
  final AppUpdateService _appUpdateService = AppUpdateService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForAppUpdate();
    });
  }

  Future<void> _checkForAppUpdate() async {
    final updateInfo = await _appUpdateService.checkForUpdate();
    if (updateInfo != null && mounted) {
      _showUpdateDialog();
    }
  }

  void _showUpdateDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            icon: const Icon(
              Icons.system_update_outlined,
              size: 48,
              color: Colors.blueAccent,
            ),
            title: Text(l10n.update_available_title),
            content: Text(
              l10n.update_available_message,
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.update_later),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _appUpdateService.performImmediateUpdate();
                },
                icon: const Icon(Icons.download_outlined),
                label: Text(l10n.update_now),
              ),
            ],
          ),
    );
  }

  void switchToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _registerClearSearch(VoidCallback callback) {
    _clearHomeSearch = callback;
  }

  List<Widget> get widgetOptions => [
    HomeScreen(onRegisterClearSearch: _registerClearSearch),
    const StatisticsScreen(),
    const MyBooksScreen(),
    const RandomScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0, // Only allow pop if on home screen
      onPopInvoked: (bool didPop) {
        if (!didPop && _selectedIndex != 0) {
          // If not on home screen, switch to home instead of exiting
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.app_title)),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: widgetOptions.elementAt(_selectedIndex),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int index) {
            // Clear search when navigating away from home (index 0)
            if (_selectedIndex == 0 && index != 0) {
              _clearHomeSearch?.call();
            }
            setState(() {
              _selectedIndex = index;
            });
          },
          indicatorColor: Theme.of(context).navigationBarTheme.indicatorColor,
          selectedIndex: _selectedIndex,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          destinations: <Widget>[
            NavigationDestination(
              icon: const Icon(Icons.cottage_outlined),
              label: AppLocalizations.of(context)!.home,
              tooltip: AppLocalizations.of(context)!.home,
            ),
            NavigationDestination(
              icon: const Icon(Icons.donut_large_outlined),
              label: AppLocalizations.of(context)!.statistics,
              tooltip: AppLocalizations.of(context)!.statistics,
            ),
            NavigationDestination(
              icon: const Icon(Icons.bookmark_outline_outlined),
              label: AppLocalizations.of(context)!.my_books,
              tooltip: AppLocalizations.of(context)!.my_books,
            ),
            NavigationDestination(
              icon: const Icon(Icons.shuffle_outlined),
              label: AppLocalizations.of(context)!.random,
              tooltip: AppLocalizations.of(context)!.random,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              label: AppLocalizations.of(context)!.settings,
              tooltip: AppLocalizations.of(context)!.settings,
            ),
          ],
        ),
      ),
    );
  }
}
