# 🔍 Google Cloud Console Verification Guide

## Current Issue
Getting "Google Sign-In configuration error. Please check setup."

## Your Current Configuration ✅
- **Package Name**: `com.example.tourlicity`
- **SHA-1 Fingerprint**: `80:1D:30:BA:C7:7F:04:C2:39:82:FC:9E:18:EE:A4:B0:B7:24:B2:DF`
- **Client ID**: `519507867000-6apsm3vbc2a570tbnv38cbsbe2kqsgm4.apps.googleusercontent.com`

## Step-by-Step Verification

### 1. Go to Google Cloud Console
1. Visit: https://console.cloud.google.com/
2. Select project: `mimetic-core-464412-k8`

### 2. Check APIs & Services
1. Go to **APIs & Services** → **Credentials**
2. Look for OAuth 2.0 Client IDs
3. You should see an Android client with:
   - **Name**: Android client (auto created by Google Service)
   - **Client ID**: `519507867000-6apsm3vbc2a570tbnv38cbsbe2kqsgm4.apps.googleusercontent.com`

### 3. Verify Android OAuth Client
Click on your Android OAuth client and verify:

**Package name**: `com.example.tourlicity`
**SHA-1 certificate fingerprints**: 
```
80:1D:30:BA:C7:7F:04:C2:39:82:FC:9E:18:EE:A4:B0:B7:24:B2:DF
```

### 4. Check OAuth Consent Screen
1. Go to **APIs & Services** → **OAuth consent screen**
2. Verify:
   - **User Type**: External (for testing)
   - **App name**: Tourlicity
   - **User support email**: Your email
   - **Developer contact information**: Your email

### 5. Enable Required APIs
Go to **APIs & Services** → **Library** and ensure these are enabled:
- ✅ **Google Sign-In API**
- ✅ **Google+ API** (if available)
- ✅ **People API** (recommended)

### 6. Test Users (if in testing mode)
If your OAuth consent screen is in "Testing" mode:
1. Go to **OAuth consent screen** → **Test users**
2. Add your Google account email as a test user

## Common Issues & Fixes

### Issue 1: "Configuration Error"
**Cause**: SHA-1 fingerprint mismatch
**Fix**: Ensure the SHA-1 in Google Cloud Console matches: `80:1D:30:BA:C7:7F:04:C2:39:82:FC:9E:18:EE:A4:B0:B7:24:B2:DF`

### Issue 2: "ApiException: 10"
**Cause**: OAuth client not properly configured
**Fix**: 
1. Delete existing Android OAuth client
2. Create new one with correct package name and SHA-1
3. Download new `google-services.json`

### Issue 3: "Sign-in failed"
**Cause**: App not added to test users (if in testing mode)
**Fix**: Add your Google account to test users list

## Quick Fix Steps

If verification shows issues:

1. **Delete current Android OAuth client**
2. **Create new Android OAuth client**:
   - Application type: Android
   - Package name: `com.example.tourlicity`
   - SHA-1: `80:1D:30:BA:C7:7F:04:C2:39:82:FC:9E:18:EE:A4:B0:B7:24:B2:DF`
3. **Download new google-services.json**
4. **Replace** `android/app/google-services.json`
5. **Clean and rebuild**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## Verification Commands

Run these to verify your local setup:
```bash
# Check SHA-1 fingerprint
cd android && ./gradlew signingReport

# Check package name
grep applicationId android/app/build.gradle

# Check google-services.json
cat android/app/google-services.json | grep package_name
```

## Next Steps

1. ✅ Verify Google Cloud Console setup using steps above
2. 🔄 If issues found, follow Quick Fix Steps
3. 🧪 Test Google Sign-In again
4. 📱 Check Flutter logs for detailed error information

---

**Need Help?** 
- Share screenshots of your Google Cloud Console OAuth client configuration
- Run the verification commands and share output
- Check if your Google account is added as a test user