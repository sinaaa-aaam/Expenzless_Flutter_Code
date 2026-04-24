// lib/providers/auth_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  AuthStatus _status = AuthStatus.initial;
  String?    _errorMessage;
  User?      _user;

  AuthStatus get status       => _status;
  String?    get errorMessage => _errorMessage;
  User?      get user         => _user;
  bool       get isLoggedIn   => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen((user) {
      _user   = user;
      _status = user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      notifyListeners();
    });
  }

  Future<void> signUp(String email, String password, String displayName) async {
    _setLoading();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
      await cred.user?.updateDisplayName(displayName);
      _status = AuthStatus.authenticated;
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Sign up failed');
    } finally {
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    _setLoading();
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
      _status = AuthStatus.authenticated;
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Login failed');
    } finally {
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async { await _auth.signOut(); }

  void _setLoading() { _status = AuthStatus.loading; notifyListeners(); }
  void _setError(String msg) { _status = AuthStatus.error; _errorMessage = msg; }
}
