# 🔧 Fix for ApiException: 10 (DEVELOPER_ERROR)

## Current Status: ❌ ApiException: 10
```
PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10: , null, null)
```

This error means there's a configuration mismatch between your app and Google Cloud Console.

## ✅ What's Working:
- Google Sign-In dialog appears
- SHA-1 fingerprint is correct: `80:1D:30:BA:C7:7F:04:C2:39:82:FC:9E:18:EE:A4:B0:B7:24:B2:DF`
- Package name is correct: `com.example.tourlicity`

## 🔧 Step-by-Step Fix

### Step 1: Go to Google Cloud Console
1. Visit: https://console.cloud.google.com/
2. Select project: `mimetic-core-464412-k8`
3. Go to **APIs & Services** → **Credentials**

### Step 2: Check Your OAuth Client
Look for your Android OAuth 2.0 client. It should show:
- **Application type**: Android
- **Package name**: `com.example.tourlicity`
- **SHA-1 certificate fingerprints**: `80:1D:30:BA:C7:7F:04:C2:39:82:FC:9E:18:EE:A4:B0:B7:24:B2:DF`

### Step 3: If OAuth Client is Missing or Wrong
**Delete the existing Android OAuth client and create a new one:**

1. **Delete existing client** (if any)
2. **Click "Create Credentials"** → **OAuth client ID**
3. **Application type**: Android
4. **Name**: `Tourlicity Android`
5. **Package name**: `com.example.tourlicity`
6. **SHA-1 certificate fingerprint**: `80:1D:30:BA:C7:7F:04:C2:39:82:FC:9E:18:EE:A4:B0:B7:24:B2:DF`
7. **Click "Create"**

### Step 4: Enable Required APIs
Go to **APIs & Services** → **Library** and enable:
- ✅ **Google Sign-In API**
- ✅ **People API**

### Step 5: Configure OAuth Consent Screen
1. Go to **APIs & Services** → **OAuth consent screen**
2. **User Type**: External
3. **App name**: `Tourlicity`
4. **User support email**: Your email
5. **Developer contact information**: Your email
6. **Save and Continue**

### Step 6: Add Test Users (Important!)
1. In **OAuth consent screen** → **Test users**
2. **Add your Google account email** that you're testing with
3. **Save**

### Step 7: Download New google-services.json
1. Go to **Project Settings** (gear icon)
2. **Your apps** → **Android app**
3. **Download google-services.json**
4. **Replace** your current `android/app/google-services.json`

### Step 8: Clean and Rebuild
```bash
flutter clean
flutter pub get
cd android && ./gradlew clean
cd .. && flutter run
```

## 🎯 Most Likely Cause

Based on the error, the most likely issue is that **your Google account is not added as a test user** in the OAuth consent screen.

### Quick Test:
1. Go to Google Cloud Console → OAuth consent screen → Test users
2. Add your Google account email
3. Save
4. Try signing in again

## 🔍 Verification Steps

After making changes, verify:

1. **Check OAuth client exists**:
   - Go to Credentials
   - See Android OAuth client with correct package name and SHA-1

2. **Check test users**:
   - Go to OAuth consent screen → Test users
   - Your email should be listed

3. **Check APIs enabled**:
   - Go to APIs & Services → Enabled APIs
   - Should see Google Sign-In API and People API

## 📱 Test Again

After completing the steps:
1. Run `flutter run`
2. Tap "Sign in with Google"
3. You should see successful authentication

## 🆘 If Still Not Working

Share screenshots of:
1. Your OAuth client configuration in Google Cloud Console
2. Your OAuth consent screen test users section
3. Your enabled APIs list

---

**The key fix is usually adding your Google account as a test user in the OAuth consent screen!**