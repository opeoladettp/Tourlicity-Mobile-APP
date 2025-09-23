import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/profile_completion_service.dart';
import '../utils/logger.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final ProfileCompletionService _profileService = ProfileCompletionService();
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _hasCheckedAuth = false;
  bool _requiresProfileCompletion = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get requiresProfileCompletion => _requiresProfileCompletion;
  bool get canAccessMainApp => _user != null && _user!.isProfileComplete && _user!.isActive;

  Future<void> signInWithGoogle() async {
    Logger.info('🔐 Starting Google Sign-In from AuthProvider');
    _setLoading(true);
    _clearError();
    
    try {
      Logger.info('📞 Calling AuthService.signInWithGoogle()');
      _user = await _authService.signInWithGoogle();
      
      if (_user != null) {
        Logger.info('✅ Google Sign-In successful - User: ${_user?.email}');
        _checkProfileCompletion();
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
      _requiresProfileCompletion = false;
      _hasCheckedAuth = false;
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
      if (_user != null) {
        _checkProfileCompletion();
      }
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
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? country,
    String? gender,
    String? passportNumber,
    String? profilePicture,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      _user = await _authService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        country: country,
        gender: gender,
        passportNumber: passportNumber,
        profilePicture: profilePicture,
      );
      
      if (_user != null) {
        _checkProfileCompletion();
      }
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> completeProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    DateTime? dateOfBirth,
    String? country,
    String? gender,
    String? passportNumber,
    String? profilePicture,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      _user = await _profileService.completeProfile(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        country: country,
        gender: gender,
        passportNumber: passportNumber,
        profilePicture: profilePicture,
      );
      
      if (_user != null) {
        _checkProfileCompletion();
        Logger.info('🎉 Profile completion successful!');
      }
      
      notifyListeners();
    } catch (e) {
      Logger.error('❌ Profile completion failed: $e');
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void _checkProfileCompletion() {
    if (_user != null) {
      _requiresProfileCompletion = _profileService.requiresProfileCompletion(_user!);
      
      if (_requiresProfileCompletion) {
        Logger.info('📝 Profile completion required for user: ${_user!.email}');
        Logger.info('Missing fields: ${_user!.missingProfileFields.join(', ')}');
      } else {
        Logger.info('✅ Profile is complete for user: ${_user!.email}');
      }
    }
  }

  ProfileCompletionStep getNextProfileStep() {
    if (_user == null) return ProfileCompletionStep.basicInfo;
    return _profileService.getNextStep(_user!);
  }

  String getProfileCompletionGuidance() {
    if (_user == null) return 'Please complete your profile to continue';
    return _profileService.getCompletionGuidance(_user!);
  }

  List<String> getCountries() {
    return _profileService.getCountries();
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