class AppConfig {
  // API Configuration
  static const String apiBaseUrl =
      'http://192.168.1.40:5000'; // Your computer's IP address
  // Alternative: 'http://10.0.2.2:5000' (Android emulator localhost)
  // Use 'http://localhost:5000' for iOS simulator or web
  static const Duration apiTimeout = Duration(
    seconds: 30,
  ); // Increased for real backend

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
}
