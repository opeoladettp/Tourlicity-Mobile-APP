# Google Sign-In Error 10 Fix Guide

## Current Status: 🎯 IDENTIFIED THE ISSUE

The logs show Google Sign-In is working but failing with **Error Code 10 (DEVELOPER_ERROR)**.

## What Error 10 Means:
- **DEVELOPER_ERROR**: Configuration mismatch between app and Google Cloud Console
- The SHA-1 fingerprint or package name doesn't match what's registered
- Or the OAuth client isn't properly configured

## Debug Information from Logs:
✅ **Working**: Google Sign-In button pressed
✅ **Working**: SignInHubActivity launched (dialog appeared)
❌ **Failing**: `ApiException: 10` (configuration error)

## Fix Steps:

### 1. Verify Google Cloud Console Configuration

Go to [Google Cloud Console](https://console.cloud.google.com/):
1. Select project: `mimetic-core-464412-k8`
2. Go to **APIs & Credentials** → **OAuth 2.0 Client IDs**
3. Find your Android client and verify:

**Required Settings:**
- **Application type**: Android
- **Package name**: `com.example.tourlicity`
- **SHA-1 certificate fingerprint**: `80:1D:30:BA:C7:7F:04:C2:39:82:FC:9E:18:EE:A4:B0:B7:24:B2:DF`

### 2. Check if OAuth Client Exists

If no Android OAuth client exists:
1. Click **+ CREATE CREDENTIALS** → **OAuth 2.0 Client ID**
2. Select **Android**
3. Enter:
   - Name: `Tourlicity Android`
   - Package name: `com.example.tourlicity`
   - SHA-1: `80:1D:30:BA:C7:7F:04:C2:39:82:FC:9E:18:EE:A4:B0:B7:24:B2:DF`

### 3. Update google-services.json

After creating/updating the OAuth client:
1. Download the new `google-services.json`
2. Replace the current file in `android/app/google-services.json`
3. Run `flutter clean && flutter pub get`

### 4. Alternative: Use Web Client ID

If the Android client setup is complex, we can use the web client ID:

```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: AppConfig.googleSignInScopes,
  clientId: "519507867000-6apsm3vbc2a570tbnv38cbsbe2kqsgm4.apps.googleusercontent.com",
);
```

## Quick Test:

Try this temporary fix to see if it's a client ID issue: