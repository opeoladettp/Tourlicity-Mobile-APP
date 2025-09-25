import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import '../config/app_config.dart';
import 'api_service.dart';
import '../utils/logger.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: AppConfig.googleSignInScopes,
    // Use configuration from google-services.json only
  );
  
  // Cache to prevent duplicate profile requests
  static User? _cachedUser;
  static DateTime? _lastProfileFetch;
  static const Duration _profileCacheTimeout = Duration(minutes: 2);
  static Future<User?>? _ongoingProfileRequest;

  Future<User?> signInWithGoogle() async {
    try {
      Logger.info('🚀 Starting Google Sign-In process...');

      // Test Google Sign-In configuration first
      Logger.info('🔍 Testing Google Sign-In configuration...');

      // Check if we can access the current user (tests configuration)
      final currentUser = _googleSignIn.currentUser;
      Logger.info('📱 Current Google user: ${currentUser?.email ?? 'None'}');

      // Step 1: Sign in with Google
      Logger.info('🔑 Attempting Google Sign-In...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        Logger.warning('❌ Google Sign-In cancelled by user');
        return null;
      }

      Logger.info('✅ Google Sign-In successful for: ${googleUser.email}');

      // Step 2: Get authentication details
      Logger.info('🔐 Getting authentication tokens...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null) {
        Logger.error('❌ Failed to get Google access token');
        throw Exception('Failed to get Google access token');
      }

      Logger.info('✅ Google authentication tokens obtained');
      Logger.debug('Access token length: ${googleAuth.accessToken?.length}');

      // Step 3: Send to backend
      final requestData = {
        'google_id': googleUser.id,
        'email': googleUser.email,
        'first_name': googleUser.displayName?.split(' ').first ?? '',
        'last_name': googleUser.displayName?.split(' ').skip(1).join(' ') ?? '',
        'picture': googleUser.photoUrl, // Google profile picture
      };

      Logger.info('🔄 Sending user data to backend...');
      Logger.debug('Request data: $requestData');

      final response = await _apiService.post(
        '/auth/google',
        data: requestData,
      );

      Logger.info('✅ Backend response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        Logger.debug('📋 Auth response data: $data');
        
        // Ensure data is a Map
        if (data == null || data is! Map<String, dynamic>) {
          Logger.error('❌ Invalid response format: expected Map, got ${data.runtimeType}');
          throw Exception('Invalid authentication response format');
        }
        
        // Validate response structure
        if (data['token'] == null) {
          Logger.error('❌ No token in auth response');
          throw Exception('Authentication response missing token');
        }
        
        if (data['user'] == null) {
          Logger.error('❌ No user data in auth response');
          throw Exception('Authentication response missing user data');
        }
        
        // Ensure user data is a Map
        if (data['user'] is! Map<String, dynamic>) {
          Logger.error('❌ Invalid user data format: expected Map, got ${data['user'].runtimeType}');
          throw Exception('Invalid user data format in response');
        }
        
        await _apiService.setAccessToken(data['token']);
        Logger.info('🎉 Authentication successful! User logged in.');
        
        try {
          return User.fromJson(data['user']);
        } catch (e) {
          Logger.error('❌ Failed to parse user data: $e');
          Logger.error('📋 User data: ${data['user']}');
          throw Exception('Failed to parse user data: $e');
        }
      } else {
        Logger.error('❌ Backend authentication failed: ${response.statusCode}');
        Logger.error('📋 Response data: ${response.data}');
        throw Exception('Backend authentication failed');
      }
    } catch (e) {
      Logger.error('❌ Google Sign-In error: $e');
      Logger.error('Error type: ${e.runtimeType}');

      // Provide more specific error information
      if (e.toString().contains('PlatformException')) {
        Logger.error('🔧 This appears to be a platform configuration issue');
        Logger.error(
          '💡 Check: SHA-1 fingerprint, package name, OAuth client setup',
        );
      }

      // Sign out from Google on error
      try {
        await _googleSignIn.signOut();
      } catch (signOutError) {
        Logger.error('Failed to sign out from Google: $signOutError');
      }

      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      // Call backend logout endpoint
      await _apiService.post('/auth/logout');
    } catch (e) {
      // Ignore logout errors
    } finally {
      await _googleSignIn.signOut();
      await _apiService.clearAccessToken();
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final token = await _apiService.getAccessToken();
      if (token == null) {
        Logger.warning('⚠️ No access token found');
        return null;
      }

      // Return cached user if still valid
      if (_cachedUser != null && 
          _lastProfileFetch != null && 
          DateTime.now().difference(_lastProfileFetch!) < _profileCacheTimeout) {
        Logger.info('📋 Returning cached user profile: ${_cachedUser!.email}');
        return _cachedUser;
      }
      
      // If there's already an ongoing request, wait for it
      if (_ongoingProfileRequest != null) {
        Logger.info('⏳ Waiting for ongoing profile request...');
        return await _ongoingProfileRequest!;
      }
      
      // Start new request
      _ongoingProfileRequest = _fetchUserProfile();
      
      try {
        final result = await _ongoingProfileRequest!;
        _cachedUser = result;
        _lastProfileFetch = DateTime.now();
        return result;
      } finally {
        _ongoingProfileRequest = null;
      }
    } catch (e) {
      Logger.error('❌ Error getting current user: $e');
      return null;
    }
  }

  /// Internal method to fetch user profile
  Future<User?> _fetchUserProfile() async {
    Logger.info('🔍 Fetching current user profile from /auth/profile');
    final response = await _apiService.get('/auth/profile');
    Logger.info('📡 Profile response status: ${response.statusCode}');
    Logger.info('📋 Profile response data: ${response.data}');
    
    if (response.statusCode == 200) {
      final data = response.data;
      Logger.info('📄 Raw profile data type: ${data.runtimeType}');
      Logger.info('📄 Raw profile data: $data');
      
      // Handle different response structures
      if (data is Map<String, dynamic>) {
        // Check for 'user' key first (standard response), then 'data' key, then use response directly
        final userData = data.containsKey('user') ? data['user'] : 
                        data.containsKey('data') ? data['data'] : data;
        Logger.info('👤 User data to parse: $userData');
        
        if (userData != null && userData is Map<String, dynamic>) {
          final user = User.fromJson(userData);
          Logger.info('✅ Successfully parsed user: ${user.email}');
          Logger.info('👤 User details - First: ${user.firstName}, Last: ${user.lastName}, Phone: ${user.phoneNumber}');
          return user;
        } else {
          Logger.error('❌ User data is null or not a Map');
        }
      } else {
        Logger.error('❌ Response data is not a Map: ${data.runtimeType}');
      }
    } else {
      Logger.error('❌ Profile request failed with status: ${response.statusCode}');
    }
    return null;
  }

  Future<User> resetToGoogleProfilePicture(String googlePictureUrl) async {
    try {
      Logger.info('🔄 Resetting profile picture to Google picture');
      
      final response = await _apiService.put(
        '/auth/reset-google-picture',
        data: {
          'google_picture_url': googlePictureUrl,
        },
      );

      if (response.statusCode == 200) {
        Logger.info('✅ Profile picture reset to Google picture successfully');
        return User.fromJson(response.data['user']);
      } else {
        Logger.error('❌ Failed to reset profile picture: ${response.statusCode}');
        throw Exception('Failed to reset profile picture to Google picture');
      }
    } catch (e) {
      Logger.error('❌ Error resetting profile picture: $e');
      rethrow;
    }
  }

  Future<User> updateProfile({
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? profilePicture,
    DateTime? dateOfBirth,
    String? country,
    String? gender,
    String? passportNumber,
  }) async {
    final response = await _apiService.put(
      '/auth/profile',
      data: {
        'first_name': firstName,
        'last_name': lastName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (profilePicture != null) 'profile_picture': profilePicture,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth.toIso8601String().split('T')[0],
        if (country != null) 'country': country,
        if (gender != null) 'gender': gender,
        if (passportNumber != null) 'passport_number': passportNumber,
      },
    );

    if (response.statusCode == 200) {
      final data = response.data;
      
      if (data == null || data is! Map<String, dynamic>) {
        throw Exception('Invalid response format from profile update');
      }
      
      final userData = data.containsKey('user') ? data['user'] : data;
      
      if (userData == null || userData is! Map<String, dynamic>) {
        throw Exception('Invalid user data in profile update response');
      }
      
      return User.fromJson(userData);
    }

    throw Exception('Failed to update profile: ${response.statusCode}');
  }
  
  /// Clear cached user data (call when user data is updated)
  static void clearUserCache() {
    _cachedUser = null;
    _lastProfileFetch = null;
    _ongoingProfileRequest = null;
  }
  
  /// Instance method to clear user cache
  void clearCache() {
    clearUserCache();
  }
}