# Complete Tourlicity Setup Guide

## 🚀 Quick Start (5 minutes)

### Step 1: Start Your Backend
```bash
# In your backend directory
npm run dev
# or
npm start
```
**Verify**: Open http://localhost:3000/health in browser - should show `{"status":"HEALTHY"}`

### Step 2: Test Flutter App
```bash
# In your Flutter project directory
flutter clean
flutter pub get
flutter run
```

### Step 3: Test Authentication
1. **Mock Sign-In** (immediate testing):
   - Click "Continue with Mock User (Testing)"
   - This bypasses Google OAuth for testing

2. **Google Sign-In** (after setup):
   - Click "Continue with Google"
   - Should redirect to Google OAuth

## 📱 Platform-Specific Configuration

### For Android Emulator
If testing on Android emulator, update the API URL:

```dart
// lib/config/app_config.dart
static const String apiBaseUrl = 'http://10.0.2.2:3000';
```

### For iOS Simulator / Web
```dart
// lib/config/app_config.dart
static const String apiBaseUrl = 'http://localhost:3000';
```

## 🔐 Google OAuth Setup (Complete)

### Your Current Configuration
- **Google Client ID**: `519507867000-q7afm0sitg8g1r5860u4ftclu60fb376.apps.googleusercontent.com`
- **Package Name**: `com.example.tourlicity`
- **Backend URL**: `http://localhost:3000`

### Google Cloud Console Setup
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project (or create one)
3. Enable Google Sign-In API
4. Go to "Credentials" → "OAuth 2.0 Client IDs"

### Required OAuth Clients
Create **TWO** OAuth clients:

#### 1. Android Application
- **Type**: Android
- **Package name**: `com.example.tourlicity`
- **SHA-1 certificate**: Get with command below

#### 2. Web Application  
- **Type**: Web application
- **Authorized redirect URIs**: `http://localhost:3000/api/v1/auth/google/callback`

### Get SHA-1 Certificate
```bash
# For debug builds (development)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Look for SHA1 fingerprint like: A1:B2:C3:D4:E5:F6...
```

## 🧪 Testing Scenarios

### Scenario 1: Mock Authentication (Always Works)
1. Start backend: `npm run dev`
2. Start Flutter: `flutter run`
3. Click "Continue with Mock User (Testing)"
4. **Expected**: Navigate to "My Tours" screen
5. **Test**: Try creating tours, searching, etc.

### Scenario 2: Google Authentication
1. Complete Google Cloud Console setup
2. Add SHA-1 fingerprint
3. Start backend: `npm run dev`
4. Start Flutter: `flutter run`
5. Click "Continue with Google"
6. **Expected**: Google OAuth flow
7. **Test**: Complete authentication

### Scenario 3: Backend Integration
1. Use Mock Sign-In to get authenticated
2. Try tour search: Enter any join code
3. Try tour creation (if provider/admin)
4. **Expected**: API calls to your backend

## 🐛 Troubleshooting

### Issue: "Continue with Google" does nothing
**Solution**: 
1. Check SHA-1 fingerprint is added to Google Cloud Console
2. Verify OAuth clients are created (Android + Web)
3. Check console logs for detailed errors

### Issue: Network errors / API calls fail
**Solutions**:
- **Android Emulator**: Change API URL to `http://10.0.2.2:3000`
- **iOS Simulator**: Use `http://localhost:3000`
- **Backend not running**: Start with `npm run dev`

### Issue: CORS errors
**Solution**: Your backend already has CORS configured for:
- `http://localhost:3000`
- `http://localhost:3001` 
- `10.0.2.2:3000`

### Issue: Google OAuth redirect fails
**Solution**: Add this redirect URI in Google Cloud Console:
`http://localhost:3000/api/v1/auth/google/callback`

## 📊 Backend API Testing

### Test Backend Health
```bash
curl http://localhost:3000/health
# Expected: {"status":"HEALTHY"}
```

### Test Google OAuth Redirect
```bash
curl -I http://localhost:3000/api/v1/auth/google
# Expected: 302 redirect to accounts.google.com
```

### Test API Documentation
Open: http://localhost:3000/api-docs

## 🔄 Development Workflow

### Daily Development
1. **Start Backend**: `npm run dev`
2. **Start Flutter**: `flutter run`
3. **Use Mock Sign-In** for quick testing
4. **Use Google Sign-In** for full OAuth testing

### When Making Changes
```bash
# After code changes
flutter hot reload  # or 'r' in terminal

# After dependency changes
flutter clean
flutter pub get
flutter run
```

### Debugging
- **Flutter Console**: Shows detailed logs with 🔐, 📱, 🎫 emojis
- **Backend Logs**: Check your backend terminal
- **Browser DevTools**: For web testing

## 🚀 Production Deployment

### Environment Variables
Update for production:
```dart
// lib/config/app_config.dart
static const String apiBaseUrl = 'https://api.tourlicity.com';
```

### Google OAuth Production
- Add production redirect URIs
- Use production SHA-1 certificates
- Update package name if needed

## 📋 Checklist

### Backend Setup ✅
- [x] Environment variables configured
- [x] Google OAuth credentials set
- [x] CORS configured for Flutter
- [x] MongoDB and Redis running
- [ ] Backend server running (`npm run dev`)

### Flutter Setup ✅
- [x] Dependencies installed
- [x] Google Client ID configured
- [x] API base URL set
- [x] Mock authentication available
- [x] Android build configuration updated

### Google OAuth Setup
- [ ] Google Cloud Console project created
- [ ] Android OAuth client created
- [ ] Web OAuth client created  
- [ ] SHA-1 fingerprint added
- [ ] Redirect URIs configured

### Testing
- [ ] Backend health check passes
- [ ] Mock sign-in works
- [ ] Google sign-in works
- [ ] API calls successful
- [ ] Tour creation/search works

## 🎯 Success Criteria

### ✅ App is working when:
1. **Mock Sign-In**: Takes you to My Tours screen
2. **Google Sign-In**: Completes OAuth flow successfully
3. **API Calls**: Backend responds to tour searches/creation
4. **Navigation**: Role-based routing works
5. **Error Handling**: Clear error messages shown

### 🔧 Next Steps After Basic Setup:
1. Test all user roles (Tourist, Provider, System Admin)
2. Implement document upload functionality
3. Add real-time notifications
4. Set up push notifications
5. Add offline support

---

**Need Help?** 
- Check console logs for detailed error messages
- Use Mock Sign-In to test app functionality
- Verify backend is running on port 3000
- Ensure Google OAuth clients are properly configured