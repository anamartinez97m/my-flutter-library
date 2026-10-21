import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:myrandomlibrary/config/v2_design_system.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Web navigation shell
//
// On web, wide windows get a side NavigationRail wrapped around the app's
// navigator (via MaterialApp.builder) so it stays visible on pushed screens.
// Mobile apps and narrow browser windows keep NewNavigationScreen's bottom bar.
// ─────────────────────────────────────────────────────────────────────────────

const double kWebRailMinWidth = 600;
const double kWebRailExtendedMinWidth = 1200;

bool useWebRail(BuildContext context) =>
    kIsWeb && MediaQuery.sizeOf(context).width >= kWebRailMinWidth;

class AppNavigationController extends ChangeNotifier {
  AppNavigationController._() {
    _loadExtendedPreference();
  }

  static final AppNavigationController instance = AppNavigationController._();

  static const String _extendedKey = 'web_nav_rail_extended';

  int _selectedIndex = 0;
  bool _shellActive = false;
  bool _extended = true;
  final List<Route<dynamic>> _routes = [];

  int get selectedIndex => _selectedIndex;
  bool get shellActive => _shellActive;
  bool get extended => _extended;
  bool get popupOpen => _routes.any((r) => r is PopupRoute);

  late final NavigatorObserver observer = _RouteTracker(this);

  VoidCallback? onLeaveHome;

  void selectTab(int index) {
    if (_selectedIndex == 0 && index != 0) onLeaveHome?.call();
    if (_selectedIndex == index) return;
    _selectedIndex = index;
    notifyListeners();
  }

  /// Pops back to the shell, then switches tab. Stops if a screen blocks the
  /// pop (e.g. unsaved changes) and lets it show its own confirmation.
  Future<void> openTab(int index) async {
    final navigator = NotificationService.navigatorKey.currentState;
    while (navigator != null && _routes.length > 1) {
      if (_routes.last.popDisposition == RoutePopDisposition.doNotPop) {
        await navigator.maybePop();
        return;
      }
      navigator.pop();
    }
    selectTab(index);
  }

  void setShellActive(bool active) {
    if (_shellActive == active) return;
    _shellActive = active;
    notifyListeners();
  }

  Future<void> toggleExtended() async {
    _extended = !_extended;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_extendedKey, _extended);
  }

  Future<void> _loadExtendedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_extendedKey);
    if (stored != null && stored != _extended) {
      _extended = stored;
      notifyListeners();
    }
  }

  void _routesChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }
}

class _RouteTracker extends NavigatorObserver {
  _RouteTracker(this.controller);

  final AppNavigationController controller;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    controller._routes.add(route);
    controller._routesChanged();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    controller._routes.remove(route);
    controller._routesChanged();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    controller._routes.remove(route);
    controller._routesChanged();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : controller._routes.indexOf(oldRoute);
    if (newRoute != null) {
      if (index >= 0) {
        controller._routes[index] = newRoute;
      } else {
        controller._routes.add(newRoute);
      }
    } else if (index >= 0) {
      controller._routes.removeAt(index);
    }
    controller._routesChanged();
  }
}

class AppNavigationDestination {
  const AppNavigationDestination(this.icon, this.label);

  final IconData icon;
  final String label;
}

List<AppNavigationDestination> appNavigationDestinations(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return [
    AppNavigationDestination(Icons.cottage_outlined, l10n.home),
    AppNavigationDestination(Icons.bar_chart_outlined, l10n.statistics),
    AppNavigationDestination(Icons.bookmark_outline_outlined, l10n.my_books),
    AppNavigationDestination(Icons.shuffle_outlined, l10n.random),
    AppNavigationDestination(Icons.settings_outlined, l10n.settings),
  ];
}

class WebNavigationShell extends StatelessWidget {
  const WebNavigationShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    final controller = AppNavigationController.instance;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.shellActive || !useWebRail(context)) return child;
        final canExtend =
            MediaQuery.sizeOf(context).width >= kWebRailExtendedMinWidth;
        return _OverlayHost(
          child: Row(
            children: [
              IgnorePointer(
                ignoring: controller.popupOpen,
                child: _WebNavigationRail(
                  controller: controller,
                  canExtend: canExtend,
                  extended: canExtend && controller.extended,
                ),
              ),
              Container(width: 1, color: V2Colors.primary),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}

/// MaterialApp.builder sits above the navigator's Overlay, so give the rail
/// its own one for tooltips.
class _OverlayHost extends StatefulWidget {
  const _OverlayHost({required this.child});

  final Widget child;

  @override
  State<_OverlayHost> createState() => _OverlayHostState();
}

class _OverlayHostState extends State<_OverlayHost> {
  late final OverlayEntry _entry = OverlayEntry(
    builder: (context) => widget.child,
  );

  @override
  void didUpdateWidget(covariant _OverlayHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    _entry.markNeedsBuild();
  }

  @override
  void dispose() {
    _entry.remove();
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Overlay(initialEntries: [_entry]);
  }
}

class _WebNavigationRail extends StatelessWidget {
  const _WebNavigationRail({
    required this.controller,
    required this.canExtend,
    required this.extended,
  });

  final AppNavigationController controller;
  final bool canExtend;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final destinations = appNavigationDestinations(context);
    final labelStyle = TextStyle(
      fontFamily: V2Typography.family,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: V2Colors.textSecondary,
    );
    return Material(
      color: V2Colors.background,
      child: SafeArea(
        right: false,
        child: NavigationRail(
          backgroundColor: V2Colors.background,
          extended: extended,
          minWidth: 72,
          minExtendedWidth: 220,
          indicatorColor: V2Colors.control,
          indicatorShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          selectedIconTheme: IconThemeData(color: V2Colors.primary, size: 22),
          unselectedIconTheme: IconThemeData(
            color: V2Colors.textSecondary,
            size: 22,
          ),
          selectedLabelTextStyle: labelStyle.copyWith(
            color: V2Colors.primary,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelTextStyle: labelStyle,
          labelType: NavigationRailLabelType.none,
          leading: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child:
                canExtend
                    ? IconButton(
                      onPressed: controller.toggleExtended,
                      tooltip: extended ? l10n.collapse_menu : l10n.expand_menu,
                      color: V2Colors.textSecondary,
                      icon: Icon(
                        extended ? Icons.menu_open_outlined : Icons.menu,
                      ),
                    )
                    : const SizedBox(height: 40),
          ),
          selectedIndex: controller.selectedIndex,
          onDestinationSelected: controller.openTab,
          destinations: [
            for (final destination in destinations)
              NavigationRailDestination(
                icon:
                    extended
                        ? Icon(destination.icon)
                        : Tooltip(
                          message: destination.label,
                          child: Icon(destination.icon),
                        ),
                label: Text(destination.label),
              ),
          ],
        ),
      ),
    );
  }
}
