import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

/// Authentication provider for state management
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  UserModel? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  User? get currentUser => _authService.currentUser;

  AuthProvider() {
    _initAuthListener();
  }

  /// Initialize auth state listener
  void _initAuthListener() {
    _authService.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        try {
          final userData = await _authService.getUserData(firebaseUser.uid);
          _user = userData;
          
          // Save user data to local database
          if (userData != null) {
            await _databaseService.saveUser(userData.toJson());
          }
        } catch (e) {
          debugPrint('Error loading user data: $e');
        }
      } else {
        _user = null;
      }
      
      // Mark as initialized
      _isInitialized = true;
      notifyListeners();
    });
  }

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Set error message
  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      final user = await _authService.signInWithEmail(email, password);
      _user = user;

      // Save to local database
      await _databaseService.saveUser(user.toJson());

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Sign up with email and password
  Future<bool> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      _setLoading(true);
      _setError(null);

      final user = await _authService.signUpWithEmail(email, password, name);
      _user = user;

      // Save to local database
      await _databaseService.saveUser(user.toJson());

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _setError(null);

      final user = await _authService.signInWithGoogle();
      _user = user;

      // Save to local database
      await _databaseService.saveUser(user.toJson());

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      _setError(null);

      await _authService.signOut();
      await _databaseService.clearSessionData();
      
      _user = null;
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _setError(null);

      await _authService.resetPassword(email);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Reload user data
  Future<void> reloadUser() async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser != null) {
      try {
        final userData = await _authService.getUserData(currentUser.uid);
        _user = userData;
        
        // Update local database
        if (userData != null) {
          await _databaseService.saveUser(userData.toJson());
        }
        
        notifyListeners();
      } catch (e) {
        debugPrint('Error reloading user data: $e');
      }
    }
  }
}
