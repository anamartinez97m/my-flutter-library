import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/providers/feature_flag_provider.dart';
import 'package:myrandomlibrary/screens/new_ui/new_home_screen.dart';
import 'package:myrandomlibrary/screens/my_books.dart';
import 'package:myrandomlibrary/screens/random.dart';
import 'package:myrandomlibrary/screens/settings.dart';
import 'package:myrandomlibrary/screens/statistics.dart';
import 'package:myrandomlibrary/services/app_update_service.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NEW UI — Navigation Shell
//
// This is the entry point for the redesigned UI. It mirrors NavigationScreen
// but imports screens from lib/screens/new_ui/ as they are created.
//
// To swap in a redesigned screen:
//   1. Create lib/screens/new_ui/<name>_screen.dart
//   2. Replace the matching import above with the new_ui version
//   3. Update widgetOptions below
//
// The "New UI" AppBar action lets dev users switch back to the old UI at any
// time without needing to navigate to the old settings screen.
// ─────────────────────────────────────────────────────────────────────────────

class NewNavigationScreen extends StatefulWidget {
  const NewNavigationScreen({super.key});

  @override
  State<NewNavigationScreen> createState() => _NewNavigationScreenState();
}

class _NewNavigationScreenState extends State<NewNavigationScreen> {
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
            icon: Icon(
              Icons.system_update_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
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
    NewHomeScreen(onRegisterClearSearch: _registerClearSearch),
    const StatisticsScreen(),
    const MyBooksScreen(),
    const RandomScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        textTheme: base.textTheme.apply(fontFamily: 'Manrope'),
        appBarTheme: base.appBarTheme.copyWith(
          titleTextStyle: (base.appBarTheme.titleTextStyle ?? const TextStyle())
              .copyWith(fontFamily: 'Manrope'),
        ),
      ),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop && _selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF43102B),
          foregroundColor: Colors.white,
          title: Text(
            AppLocalizations.of(context)!.app_title,
            style: const TextStyle(color: Colors.white, fontFamily: 'Manrope'),
          ),
          actions: [
            // Dev-only escape hatch — tap to switch back to the old UI
            Consumer<FeatureFlagProvider>(
              builder: (context, flags, _) {
                if (!flags.isDevUser) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.undo_rounded),
                  tooltip: 'Switch to old UI',
                  onPressed: () => flags.setToggle(false),
                );
              },
            ),
          ],
        ),
        body: SafeArea(child: widgetOptions.elementAt(_selectedIndex)),
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int index) {
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
