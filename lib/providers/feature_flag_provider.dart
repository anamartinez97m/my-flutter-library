import 'package:flutter/foundation.dart';
import 'package:myrandomlibrary/services/google_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controls which features are gated behind a developer email whitelist.
///
/// `isDevUser`    — true when the signed-in Google account is in [_devEmails].
/// `newUiEnabled` — true when isDevUser AND the in-app toggle is switched on.
///
/// To ship the new UI: remove the gate in main.dart and delete this class.
class FeatureFlagProvider extends ChangeNotifier {
  static const String _prefKey = 'new_ui_enabled';

  /// Emails that have access to in-development features.
  static const List<String> _devEmails = ['anamartinez97m@gmail.com'];

  bool _isDevUser = false;
  bool _toggleEnabled = false;

  /// True when the signed-in account is in the developer whitelist.
  bool get isDevUser => _isDevUser;

  /// True when [isDevUser] AND the Settings toggle is switched on.
  bool get newUiEnabled => _isDevUser && _toggleEnabled;

  FeatureFlagProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _toggleEnabled = prefs.getBool(_prefKey) ?? false;

    final current = GoogleAuthService.instance.currentUser;
    _isDevUser = _checkEmail(current?.email);

    notifyListeners();

    GoogleAuthService.instance.authStateChanges.listen((user) {
      final dev = _checkEmail(user?.email);
      if (_isDevUser != dev) {
        _isDevUser = dev;
        notifyListeners();
      }
    });
  }

  /// Called from Settings to flip the toggle.
  Future<void> setToggle(bool value) async {
    _toggleEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }

  static bool _checkEmail(String? email) =>
      email != null && _devEmails.contains(email);
}
