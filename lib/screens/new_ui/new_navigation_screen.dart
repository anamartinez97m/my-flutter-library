import 'package:flutter/material.dart';
import 'package:myrandomlibrary/config/v2_design_system.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/screens/new_ui/new_home_screen.dart';
import 'package:myrandomlibrary/screens/new_ui/new_my_books_screen.dart';
import 'package:myrandomlibrary/screens/new_ui/new_random_screen.dart';
import 'package:myrandomlibrary/screens/new_ui/web_navigation_shell.dart';
import 'package:myrandomlibrary/screens/settings.dart';
import 'package:myrandomlibrary/screens/statistics.dart';
import 'package:myrandomlibrary/services/app_update_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NEW UI — Navigation Shell
//
// This is the entry point for the redesigned UI. It imports screens from
// lib/screens/new_ui/ as they are created.
//
// To swap in a redesigned screen:
//   1. Create lib/screens/new_ui/<name>_screen.dart
//   2. Replace the matching import above with the new_ui version
//   3. Update widgetOptions below
//
// ─────────────────────────────────────────────────────────────────────────────

class NewNavigationScreen extends StatefulWidget {
  const NewNavigationScreen({super.key});

  @override
  State<NewNavigationScreen> createState() => _NewNavigationScreenState();
}

class _NewNavigationScreenState extends State<NewNavigationScreen> {
  final AppNavigationController _navigation = AppNavigationController.instance;
  VoidCallback? _clearHomeSearch;
  final AppUpdateService _appUpdateService = AppUpdateService();

  int get _selectedIndex => _navigation.selectedIndex;

  @override
  void initState() {
    super.initState();
    _navigation.addListener(_onNavigationChanged);
    _navigation.onLeaveHome = () => _clearHomeSearch?.call();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigation.setShellActive(true);
      _checkForAppUpdate();
    });
  }

  @override
  void dispose() {
    _navigation.removeListener(_onNavigationChanged);
    _navigation.onLeaveHome = null;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _navigation.setShellActive(false),
    );
    super.dispose();
  }

  void _onNavigationChanged() {
    if (mounted) setState(() {});
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

  void switchToTab(int index) => _navigation.selectTab(index);

  void _registerClearSearch(VoidCallback callback) {
    _clearHomeSearch = callback;
  }

  List<Widget> get widgetOptions => [
    NewHomeScreen(onRegisterClearSearch: _registerClearSearch),
    const StatisticsScreen(),
    const NewMyBooksScreen(),
    const NewRandomScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        textTheme: base.textTheme.apply(fontFamily: V2Typography.family),
        appBarTheme: base.appBarTheme.copyWith(
          titleTextStyle: (base.appBarTheme.titleTextStyle ?? const TextStyle())
              .copyWith(fontFamily: V2Typography.family),
        ),
      ),
      child: _buildContent(context),
    );
  }

  Widget _buildInlineHeader(BuildContext context) {
    return Container(
      color: V2Colors.background,
      padding: const EdgeInsets.fromLTRB(25, 20, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.app_title,
              style: TextStyle(
                fontFamily: V2Typography.family,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: V2Colors.primary,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop && _selectedIndex != 0) {
          _navigation.selectTab(0);
        }
      },
      child: Scaffold(
        backgroundColor: V2Colors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildInlineHeader(context),
              Expanded(child: widgetOptions.elementAt(_selectedIndex)),
            ],
          ),
        ),
        bottomNavigationBar:
            useWebRail(context) ? null : _buildBottomBar(context),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(height: 1, color: V2Colors.primary),
        NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 64,
            backgroundColor: V2Colors.background,
            indicatorColor: V2Colors.control,
            indicatorShape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return IconThemeData(color: V2Colors.primary, size: 22);
              }
              return IconThemeData(color: V2Colors.textSecondary, size: 22);
            }),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          ),
          child: NavigationBar(
            onDestinationSelected: _navigation.selectTab,
            selectedIndex: _selectedIndex,
            destinations: <Widget>[
              for (final destination in appNavigationDestinations(context))
                NavigationDestination(
                  icon: Icon(destination.icon),
                  label: destination.label,
                  tooltip: destination.label,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
