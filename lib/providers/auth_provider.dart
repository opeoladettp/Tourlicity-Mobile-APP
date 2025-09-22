import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _hasCheckedAuth = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> signInWithGoogle() async {
    Logger.info('🔐 Starting Google Sign-In from AuthProvider');
    _setLoading(true);
    _clearError();
    
    try {
      Logger.info('📞 Calling AuthService.signInWithGoogle()');
      _user = await _authService.signInWithGoogle();
      
      if (_user != null) {
        Logger.info('✅ Google Sign-In successful - User: ${_user?.email}');
      } else {
        Logger.warning('⚠️ Google Sign-In returned null user');
      }
      
      notifyListeners();
    } catch (e) {
      Logger.error('❌ Google Sign-In error in AuthProvider: $e');
      _setError(e.toString());
    } finally {
      _setLoading(false);
      Logger.info('🏁 Google Sign-In process completed');
    }
  }



  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> checkAuthStatus() async {
    if (_hasCheckedAuth) {
      return; // Prevent multiple checks
    }
    
    _hasCheckedAuth = true;
    _setLoading(true);
    try {
      _user = await _authService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      _user = null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      _user = await _authService.updateProfile(
        firstName: firstName,
        lastName: lastName,
      );
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}