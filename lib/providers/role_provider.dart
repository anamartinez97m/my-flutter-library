import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum UserRole { basic, premium, admin }

class RoleProvider extends ChangeNotifier {
  final FirebaseAuth _auth;
  late final StreamSubscription<User?> _subscription;

  UserRole _role = UserRole.basic;
  bool _isLoading = true;
  int _loadGeneration = 0;

  RoleProvider({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance {
    _subscription = _auth.idTokenChanges().listen(_loadRole);
    _loadRole(_auth.currentUser);
  }

  UserRole get role => _role;
  bool get isLoading => _isLoading;
  bool get isAdmin => _role == UserRole.admin;
  bool get isPremium => _role == UserRole.premium || isAdmin;

  Future<void> forceRefresh() async {
    final user = _auth.currentUser;
    if (user == null) {
      _setRole(UserRole.basic);
      return;
    }
    await _loadRole(user, forceRefresh: true);
  }

  Future<void> _loadRole(User? user, {bool forceRefresh = false}) async {
    final generation = ++_loadGeneration;
    if (user == null) {
      _setRole(UserRole.basic);
      return;
    }

    try {
      final token = await user.getIdTokenResult(forceRefresh);
      if (generation != _loadGeneration || _auth.currentUser?.uid != user.uid) {
        return;
      }
      _setRole(_parseRole(token.claims?['role']));
    } catch (error) {
      if (generation != _loadGeneration) return;
      debugPrint('Error loading user role: $error');
      _setRole(UserRole.basic);
    }
  }

  void _setRole(UserRole role) {
    final changed = _role != role || _isLoading;
    _role = role;
    _isLoading = false;
    if (changed) notifyListeners();
  }

  static UserRole _parseRole(Object? role) => switch (role) {
    'admin' => UserRole.admin,
    'premium' => UserRole.premium,
    _ => UserRole.basic,
  };

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
