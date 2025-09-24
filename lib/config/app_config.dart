class AppConfig {
  // API Configuration
  static const String apiBaseUrl =
      'http://192.168.1.2:5000'; // Your computer's Wi-Fi IP address
  // Alternative: 'http://10.0.2.2:5000' (Android emulator localhost)
  // Use 'http://localhost:5000' for iOS simulator or web
  static const Duration apiTimeout = Duration(
    seconds: 60,
  ); // Increased timeout for network issues

  // App Information
  static const String appName = 'Tourlicity';
  static const String appVersion = '1.0.0';

  // Google Sign-In Configuration
  static const List<String> googleSignInScopes = ['email', 'profile'];
  static const String googleClientId =
      '519507867000-6apsm3vbc2a570tbnv38cbsbe2kqsgm4.apps.googleusercontent.com';

  // Storage Keys
  static const String accessTokenKey = 'access_token';

  // UI Configuration
  static const Duration loadingDelay = Duration(milliseconds: 300);
  static const int maxRetryAttempts = 3;

  // User Roles
  static const String roleSystemAdmin = 'system_admin';
  static const String roleProviderAdmin = 'provider_admin';
  static const String roleTourist = 'tourist';

  // Tour Status
  static const String tourStatusDraft = 'draft';
  static const String tourStatusPublished = 'published';
  static const String tourStatusActive = 'active';
  static const String tourStatusCompleted = 'completed';
  static const String tourStatusCancelled = 'cancelled';

  // Registration Status
  static const String registrationStatusPending = 'pending';
  static const String registrationStatusApproved = 'approved';
  static const String registrationStatusRejected = 'rejected';
  static const String registrationStatusCancelled = 'cancelled';

  // Pagination
  static const int defaultPageSize = 10;
  static const int maxPageSize = 50;
}
