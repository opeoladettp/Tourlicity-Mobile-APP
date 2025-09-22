# Google Sign-In Setup Guide

## Issues Fixed

### 1. ✅ Google Services Plugin

- **Problem**: Google Services buildscript was commented out in `android/build.gradle.kts`
- **Solution**: Uncommented and updated to latest version (4.4.0)

### 2. ✅ Android Manifest Configuration

- **Added**: Internet permission
- **Added**: Google Play Services version meta-data

### 3. ✅ GoogleSignIn Client ID

- **Added**: Client ID configuration in AuthService
- **Added**: Proper initialization in main.dart

## Current Configuration

### Files Updated:

1. `android/build.gradle.kts` - Enabled Google Services plugin
2. `android/app/src/main/AndroidManifest.xml` - Added permissions and meta-data
3. `lib/services/auth_service.dart` - Added client ID to GoogleSignIn
4. `lib/main.dart` - Added proper initialization

### Next Steps to Complete Setup:

#### 1. Verify google-services.json

Make sure your `android/app/google-services.json` contains the correct configuration for your app:

- Package name should match: `com.example.tourlicity`
- OAuth client should be configured for Android

#### 2. Clean and Rebuild

```bash
flutter clean
flutter pub get
cd android && ./gradlew clean && cd ..
flutter run
```

#### 3. Test Google Sign-In

The error should now be resolved. If you still get issues:

1. **Check SHA-1 fingerprint** in Firebase Console:

   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

2. **Verify OAuth Client** in Google Cloud Console:

   - Go to APIs & Credentials
   - Check OAuth 2.0 Client IDs
   - Ensure Android client is configured with correct package name and SHA-1

3. **Check Client ID** matches in:
   - `lib/config/app_config.dart`
   - Firebase Console OAuth settings

## Troubleshooting

### Common Issues:

1. **"sign_in_failed"** - Usually means SHA-1 fingerprint mismatch
2. **"network_error"** - Check internet connection and API endpoints
3. **"sign_in_canceled"** - User cancelled the sign-in process

### Debug Steps:

1. Check Android logs: `flutter logs`
2. Verify google-services.json is in correct location
3. Ensure Firebase project is properly configured
4. Test with a fresh `flutter clean` and rebuild

## Configuration Files Status:

- ✅ `pubspec.yaml` - google_sign_in dependency added
- ✅ `android/build.gradle.kts` - Google services plugin enabled
- ✅ `android/app/build.gradle.kts` - Google services plugin applied
- ✅ `android/app/google-services.json` - Present (verify contents)
- ✅ `android/app/src/main/AndroidManifest.xml` - Permissions and meta-data added
- ✅ `lib/services/auth_service.dart` - Client ID configured
- ✅ `lib/config/app_config.dart` - Google client ID defined

The Google Sign-In should now work properly!
