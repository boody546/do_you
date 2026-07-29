import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/preference_service.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  AuthStatus _status = AuthStatus.uninitialized;
  UserModel? _userModel;
  String? _errorMessage;
  String _savedRole = 'parent';

  AuthStatus get status => _status;
  UserModel? get userModel => _userModel;
  String? get errorMessage => _errorMessage;
  String get savedRole => _savedRole;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _initSession();
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _initSession() async {
    final session = await PreferenceService.getSession();
    if (session['isLoggedIn'] == true) {
      _savedRole = session['role'] ?? 'parent';
      if (_savedRole == 'child') {
        _status = AuthStatus.authenticated;
        notifyListeners();
      }
    }
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      final session = await PreferenceService.getSession();
      if (session['role'] == 'child' && session['isLoggedIn'] == true) {
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
        _userModel = null;
      }
    } else {
      _status = AuthStatus.loading;
      notifyListeners();
      _userModel = await _firestoreService.getUserProfile(user.uid);
      _status = AuthStatus.authenticated;
      await PreferenceService.saveSession(role: 'parent', email: user.email);
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      await _authService.signIn(email: email, password: password);
      await PreferenceService.saveSession(role: 'parent', email: email);
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerParent(String email, String password) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _userModel = await _authService.signUpParent(email: email, password: password);
      _status = AuthStatus.authenticated;
      await PreferenceService.saveSession(role: 'parent', email: email);
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    await PreferenceService.clearSession();
    _status = AuthStatus.unauthenticated;
    _userModel = null;
    notifyListeners();
  }
}
