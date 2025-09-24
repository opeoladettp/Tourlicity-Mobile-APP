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
  bool get canAccessMainApp =>
      _user != null && _user!.isProfileComplete && _user!.isActive;

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
        Logger.info('🔍 Auth status check - User found: ${_user!.email}');
        _checkProfileCompletion();
      } else {
        Logger.info('🔍 Auth status check - No user found');
      }
      notifyListeners();
    } catch (e) {
      Logger.error('❌ Auth status check failed: $e');
      _user = null;
    } finally {
      _setLoading(false);
    }
  }

  /// Force refresh auth status - useful after profile updates
  Future<void> refreshAuthStatus() async {
    _setLoading(true);
    try {
      _user = await _authService.getCurrentUser();
      if (_user != null) {
        Logger.info('🔄 Auth status refresh - User found: ${_user!.email}');
        _checkProfileCompletion();
      } else {
        Logger.info('🔄 Auth status refresh - No user found');
      }
      notifyListeners();
    } catch (e) {
      Logger.error('❌ Auth status refresh failed: $e');
      _user = null;
    } finally {
      _setLoading(false);
    }
  }

  /// Reset profile completion check - useful for debugging
  void resetProfileCompletionCheck() {
    if (_user != null) {
      Logger.info('🔄 Resetting profile completion check for: ${_user!.email}');
      _checkProfileCompletion();
      notifyListeners();
    }
  }

  /// Debug method to log current profile status
  void debugProfileStatus() {
    if (_user != null) {
      Logger.info('🐛 DEBUG: Current profile status for ${_user!.email}');
      Logger.info('  - Raw firstName: "${_user!.firstName}"');
      Logger.info('  - Raw lastName: "${_user!.lastName}"');
      Logger.info('  - Raw phoneNumber: "${_user!.phoneNumber}"');
      Logger.info('  - Raw dateOfBirth: ${_user!.dateOfBirth}');
      Logger.info('  - Raw country: "${_user!.country}"');
      Logger.info('  - User type: ${_user!.userType}');
      Logger.info('  - Is profile complete: ${_user!.isProfileComplete}');
      Logger.info('  - Missing fields: ${_user!.missingProfileFields}');
      Logger.info('  - Requires completion: $_requiresProfileCompletion');
    } else {
      Logger.info('🐛 DEBUG: No user logged in');
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

  Future<void> resetToGoogleProfilePicture(String googlePictureUrl) async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authService.resetToGoogleProfilePicture(googlePictureUrl);
      
      if (_user != null) {
        Logger.info('✅ Profile picture reset to Google picture successfully');
      }

      notifyListeners();
    } catch (e) {
      Logger.error('❌ Failed to reset profile picture: $e');
      _setError(e.toString());
      rethrow;
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
        Logger.info(
          '🔄 Profile completion status after update: $_requiresProfileCompletion',
        );
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
      final wasRequiringCompletion = _requiresProfileCompletion;
      _requiresProfileCompletion = _profileService.requiresProfileCompletion(
        _user!,
      );

      Logger.info('🔍 Profile completion check for user: ${_user!.email}');
      Logger.info('  - User Type: ${_user!.userType}');
      Logger.info('  - First Name: "${_user!.firstName}"');
      Logger.info('  - Last Name: "${_user!.lastName}"');
      Logger.info('  - Phone Number: "${_user!.phoneNumber}"');
      Logger.info('  - Date of Birth: ${_user!.dateOfBirth}');
      Logger.info('  - Country: "${_user!.country}"');
      Logger.info('  - Is Profile Complete: ${_user!.isProfileComplete}');
      Logger.info(
        '  - Missing Fields: ${_user!.missingProfileFields.join(', ')}',
      );
      Logger.info('  - Previous Requirement: $wasRequiringCompletion');
      Logger.info('  - Current Requirement: $_requiresProfileCompletion');

      if (_requiresProfileCompletion) {
        Logger.info('📝 Profile completion required for user: ${_user!.email}');
        Logger.info(
          'Missing fields: ${_user!.missingProfileFields.join(', ')}',
        );
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

  List<String> getGenders() {
    return _profileService.getGenders();
  }

  /// Update the current user data and notify listeners
  void updateUser(User updatedUser) {
    _user = updatedUser;
    _checkProfileCompletion();
    notifyListeners();
    Logger.info('✅ User data updated in AuthProvider');
  }

  /// Refresh user data from the server
  Future<void> refreshUser() async {
    if (_user == null) return;
    
    try {
      final refreshedUser = await _authService.getCurrentUser();
      if (refreshedUser != null) {
        updateUser(refreshedUser);
      }
    } catch (e) {
      Logger.error('❌ Failed to refresh user data: $e');
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
