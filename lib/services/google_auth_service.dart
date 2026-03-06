import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final GoogleAuthService instance = GoogleAuthService._internal();
  GoogleAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    try {
      debugPrint('Google Sign-In: Starting...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('Google Sign-In: User cancelled');
        return null;
      }

      debugPrint('Google Sign-In: Account selected: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      debugPrint(
        'Google Sign-In: Got tokens - accessToken: ${googleAuth.accessToken != null}, idToken: ${googleAuth.idToken != null}',
      );

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('Google Sign-In: Signing in with Firebase credential...');
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      debugPrint(
        'Google Sign-In successful: ${userCredential.user?.displayName}',
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'FirebaseAuthException during sign-in: ${e.code} - ${e.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint('Error during Google Sign-In: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      debugPrint('Signed out successfully');
    } catch (e) {
      debugPrint('Error during sign-out: $e');
    }
  }
}
