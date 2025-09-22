# 🔐 Google OAuth Setup Guide

## Current Status: Configuration Error

You're getting "Google Sign-In configuration error" because the Google Cloud Console setup isn't complete.

## ✅ What We Have:
- **Google Client ID**: `519507867000-q7afm0sitg8g1r5860u4ftclu60fb376.apps.googleusercontent.com`
- **Your SHA-1 Fingerprint**: `80:1D:30:BA:C7:7F:04:C2:39:82:FC:9E:18:EE:A4:B0:B7:24:B2:DF`
- **Package Name**: `com.example.tourlicity`

## 🚀 Quick Fix: Use Mock Sign-In

**For immediate testing**, use the **orange "Continue with Mock User (Testing)"** button. This bypasses Google OAuth completely and lets you test all app features.

## 🛠️ Complete Google OAuth Setup

### Step 1: Go to Google Cloud Console
1. Open [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project (or create a new one)
3. Enable the **Google Sign-In API**

### Step 2: Create OAuth 2.0 Credentials

#### Create Android OAuth Client:
1. Go to **Credentials** → **Create Credentials** → **OAuth 2.0 Client IDs**
2. Choose **Android** as application type
3. Enter these details:
   - **Package name**: `com.example.tourlicity`
   - **SHA-1 certificate fingerprint**: `80:1D:30:BA:C7:7F:04:C2:39:82:FC:9E:18:EE:A4:B0:B7:24:B2:DF`

#### Create Web OAuth Client:
1. Create another OAuth client
2. Choose **Web application** as application type
3. Add authorized redirect URI: `http://localhost:3000/api/v1/auth/google/callback`

### Step 3: Download Configuration
1. After creating the Android client, download the `google-services.json`
2. Replace the file in `android/app/google-services.json`

### Step 4: Test Google Sign-In
1. Clean and rebuild: `flutter clean && flutter pub get && flutter run`
2. Try the Google Sign-In button

## 🧪 Testing Priority

### 1. Test Mock Sign-In First ✅
- Click **"Continue with Mock User (Testing)"**
- Should work immediately without any Google setup
- Tests all app functionality

### 2. Test Backend Integration ✅
- Start your backend: `npm run dev`
- Use Mock Sign-In to authenticate
- Test tour search and creation

### 3. Test Google Sign-In (After Setup)
- Complete Google Cloud Console setup
- Click **"Continue with Google"**
- Should work with proper OAuth flow

## 🔍 Debug Google Sign-In Issues

### Common Error Messages:
- **"sign_in_failed"** → SHA-1 fingerprint not added
- **"ApiException: 10"** → OAuth client not configured
- **"Configuration error"** → google-services.json issues

### Debug Steps:
1. **Check SHA-1**: Ensure `80:1D:30:BA:C7:7F:04:C2:39:82:FC:9E:18:EE:A4:B0:B7:24:B2:DF` is added
2. **Check Package Name**: Must be exactly `com.example.tourlicity`
3. **Check Client Type**: Need both Android (type 1) and Web (type 3) clients

## 🎯 Immediate Action Plan

### Right Now:
1. **Test Mock Sign-In** → Should work perfectly
2. **Explore the app** → Test all features
3. **Test with backend** → Start backend and test API calls

### Later (Optional):
1. **Complete Google Cloud Console setup**
2. **Test Google Sign-In**
3. **Use real OAuth for production**

## 📱 Expected Behavior

### Mock Sign-In (Should Work Now):
```
Click Orange Button → Loading → Console Logs → Navigate to My Tours
```

### Google Sign-In (After Setup):
```
Click White Button → Google OAuth → Backend Verification → Navigate to Dashboard
```

---

**Current Recommendation**: Use Mock Sign-In for testing all app features. Google Sign-In can be set up later when you need production OAuth.

**Your SHA-1 Fingerprint**: `80:1D:30:BA:C7:7F:04:C2:39:82:FC:9E:18:EE:A4:B0:B7:24:B2:DF`