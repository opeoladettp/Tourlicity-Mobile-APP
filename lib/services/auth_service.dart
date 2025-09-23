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
        // Remove profile_picture for now to avoid validation issues
        // 'profile_picture': googleUser.photoUrl,
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
        
        // Validate response structure
        if (data['token'] == null) {
          Logger.error('❌ No token in auth response');
          throw Exception('Authentication response missing token');
        }
        
        if (data['user'] == null) {
          Logger.error('❌ No user data in auth response');
          throw Exception('Authentication response missing user data');
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
        return null;
      }

      final response = await _apiService.get('/auth/profile');
      if (response.statusCode == 200) {
        return User.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      return null;
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
      return User.fromJson(response.data['user']);
    }

    throw Exception('Failed to update profile');
  }
}
