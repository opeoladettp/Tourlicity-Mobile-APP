# Google Cloud Console Configuration Fix

## Current Status: Error 10 (DEVELOPER_ERROR)

The technical setup is correct, but Google Cloud Console configuration is missing or incorrect.

## Step-by-Step Fix:

### 1. Go to Google Cloud Console
Visit: https://console.cloud.google.com/

### 2. Select Your Project
- Project ID: `mimetic-core-464412-k8`
- Project Number: `519507867000`

### 3. Navigate to Credentials
- Go to **APIs & Services** → **Credentials**
- Look for **OAuth 2.0 Client IDs** section

### 4. Check Existing OAuth Clients
You should see:
- ✅ Web client: `519507867000-6apsm3vbc2a570tbnv38cbsbe2kqsgm4.apps.googleusercontent.com`
- ❌ Android client: **MISSING** (this is the problem!)

### 5. Create Android OAuth Client
Click **+ CREATE CREDENTIALS** → **OAuth 2.0 Client ID**

**Settings:**
- **Application type**: Android
- **Name**: `Tourlicity Android`
- **Package name**: `com.example.tourlicity`
- **SHA-1 certificate fingerprint**: `80:1D:30:BA:C7:7F:04:C2:39:82:FC:9E:18:EE:A4:B0:B7:24:B2:DF`

### 6. Download New google-services.json
After creating the Android client:
1. Go to **Project Settings** (gear icon)
2. Select **Your apps** tab
3. Find your Android app
4. Click **Download google-services.json**
5. Replace `android/app/google-services.json` with the new file

### 7. Alternative Quick Fix (Temporary)
If you can't access Google Cloud Console right now, try removing the serverClientId to use only the google-services.json configuration:

```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: AppConfig.googleSignInScopes,
  // Remove serverClientId to use google-services.json only
);
```

## Why This Happens:
- Your `google-services.json` was created before the Android OAuth client existed
- Google Sign-In needs both the `google-services.json` AND a properly configured Android OAuth client
- The web client ID alone isn't sufficient for Android apps

## Expected Result:
After creating the Android OAuth client and updating google-services.json:
- ✅ No Error 10
- ✅ Google Sign-In dialog works
- ✅ Authentication completes successfully
- ✅ Mock user is created and logged in

## Test the Quick Fix First:
Try the alternative quick fix (removing serverClientId) to see if that works with your current setup.