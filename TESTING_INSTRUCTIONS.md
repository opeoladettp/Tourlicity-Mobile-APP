# 🧪 Testing Instructions for Tourlicity App

## Current Status: App Running on Android ✅

The app has successfully restarted and is running on your Android device/emulator.

## 🚀 Testing Steps

### Step 1: Test Google Authentication
1. **Look for the login screen** with the button:
   - "Continue with Google" (blue/white button)

2. **Click "Continue with Google"**
   - This will attempt to authenticate with Google
   - Requires Google Cloud Console setup for full functionality
   - Without proper setup, you may see authentication errors

### Step 2: Test Backend Connection (Backend Required)
1. **Start your backend first**:
   ```bash
   # In your backend directory
   npm run dev
   ```

2. **Verify backend is running**:
   - Open http://localhost:3000/health in browser
   - Should show: `{"status":"HEALTHY"}`

3. **Test API connection in app**:
   - Try the tour search functionality
   - Look for network requests in the console

### Step 3: Test Google Sign-In (Google Cloud Setup Required)
1. **Click "Continue with Google"**
2. **Check console output** for detailed logs:
   - `🔐 Starting Google Sign-In...`
   - `📱 Google user: email@example.com`
   - `🎫 ID Token received: Yes/No`

## 📱 What You Should See

### Login Screen
```
┌─────────────────────────┐
│     🎯 Tourlicity       │
│  Modern Tour Management │
│                         │
│ [🔍 Continue with Google] │
│                         │
│ [🐛 Continue with Mock  │
│     User (Testing)]     │
└─────────────────────────┘
```

### After Mock Sign-In
```
┌─────────────────────────┐
│      My Tours           │
│                         │
│  📋 No tours found      │
│  Join a tour using a    │
│  join code              │
│                         │
│  [🔍 Search Tours]      │
└─────────────────────────┘
```

## 🔧 Troubleshooting

### Issue: App shows blank screen
**Solution**: Hot reload the app
- Press `r` in the terminal where Flutter is running
- Or save any file to trigger hot reload

### Issue: "Continue with Google" doesn't work
**Expected**: This is normal without Google Cloud Console setup
**Solution**: Set up Google Cloud Console authentication or use a different authentication method

### Issue: API calls fail
**Check**:
1. Backend is running on port 3000
2. Android emulator can reach `10.0.2.2:3000`
3. CORS is configured in your backend

### Issue: Network errors
**Android Emulator**: API URL is set to `http://10.0.2.2:3000` ✅
**Physical Device**: Change to your computer's IP address

## 📊 Testing Scenarios

### Scenario 1: Google Authentication Flow
1. ✅ App loads login screen
2. ✅ Click "Continue with Google"
3. ✅ Complete Google authentication
4. ✅ Navigate to appropriate dashboard based on user type
5. ✅ Click "Search Tours" → Tour search screen

### Scenario 2: Tour Search (Mock Data)
1. ✅ From My Tours, click "Search Tours"
2. ✅ Enter any join code (e.g., "TEST123")
3. ✅ Should show "Tour not found" (expected without backend)
4. ✅ Error handling works correctly

### Scenario 3: Backend Integration
1. ✅ Start backend server
2. ✅ Use Mock Sign-In
3. ✅ Try tour search with real join code
4. ✅ Should connect to your backend API

## 🎯 Success Indicators

### ✅ App is working correctly when:
1. **Login screen loads** with both buttons visible
2. **Mock sign-in works** → navigates to My Tours
3. **Navigation works** → can move between screens
4. **Error handling works** → shows appropriate messages
5. **UI is responsive** → buttons respond to taps

### 🔍 Console Logs to Look For
```
🔐 Starting Google Sign-In...
📱 Google user: test@example.com
🎫 ID Token received: Yes
🌐 Sending token to backend...
📡 Backend response: 200
✅ Authentication successful
```

## 📱 Current Configuration

### ✅ Configured for Android:
- **API URL**: `http://10.0.2.2:3000` (Android emulator localhost)
- **Package Name**: `com.example.tourlicity`
- **Google Client ID**: `519507867000-q7afm0sitg8g1r5860u4ftclu60fb376.apps.googleusercontent.com`

### ✅ Authentication Options:
- **Mock Sign-In**: Ready for immediate testing
- **Google Sign-In**: Configured with your credentials

## 🚀 Next Steps

### Immediate Testing:
1. **Test Mock Sign-In** → Should work immediately
2. **Explore the UI** → Navigate through different screens
3. **Test error handling** → Try invalid operations

### Backend Testing:
1. **Start your backend** → `npm run dev`
2. **Test API calls** → Tour search, creation, etc.
3. **Check network logs** → Verify API communication

### Google OAuth Testing:
1. **Complete Google Cloud Console setup**
2. **Add SHA-1 fingerprint**
3. **Test Google Sign-In flow**

---

## 🎉 Ready to Test!

Your app is running successfully on Android. Start with **Mock Sign-In** to test all the functionality, then move on to backend integration and Google OAuth testing.

**Current Status**: ✅ App Running → ✅ Ready for Testing → 🧪 Start with Mock Sign-In