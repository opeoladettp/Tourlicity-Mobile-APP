# Tourlicity Flutter App - Backend Integration Guide

## Overview
This guide covers the integration between the Tourlicity Flutter mobile app and your local backend API running on `http://localhost:3000/api/v1`.

## ✅ Completed Integration Updates

### 1. API Configuration
- **Base URL**: Updated to `http://localhost:3000/api/v1`
- **Timeout**: 30 seconds for all requests
- **Headers**: Automatic JWT token injection

### 2. Authentication Flow
- **Google OAuth**: Integrated with your `/auth/google` endpoint
- **Token Management**: JWT access tokens with automatic refresh
- **Profile Completion**: Uses `/auth/profile/complete` endpoint

### 3. Data Models Updated
All models have been updated to match your backend API response format:

#### User Model
- Uses `name` instead of separate `first_name`/`last_name`
- Includes `profile_completed` boolean flag
- Maps to your user schema with `created_date`/`updated_date`

#### Tour Model
- Uses `tour_name` instead of `name`
- Includes `max_tourists`, `current_registrations`, `remaining_spots`
- Supports `price_per_person`, `currency`, `is_featured`
- Includes `tags` array and `duration_days`

#### Registration Model
- Uses `custom_tour_id` and `tourist_id`
- Includes `confirmation_code` and `payment_status`
- Supports emergency contact information

### 4. API Endpoints Mapped

#### Authentication
- `POST /auth/google/verify` - Google OAuth verification
- `GET /auth/profile` - Get current user profile
- `POST /auth/profile/complete` - Complete user profile
- `POST /auth/refresh` - Refresh JWT tokens

#### Tours
- `GET /tours` - Get tours with filtering (provider-specific)
- `POST /tours` - Create new tour
- `PUT /tours/{id}` - Update tour
- `DELETE /tours/{id}` - Delete tour
- `POST /tours/join` - Join tour by code

#### Registrations
- `GET /registrations/tourist/me` - Get user's registrations
- `POST /registrations/{id}/cancel` - Cancel registration
- `GET /registrations/stats` - Get provider statistics

## 🚀 How to Test the Integration

### 1. Start Your Backend
```bash
# Make sure your backend is running on port 3000
npm run dev
# or
npm start
```

### 2. Configure Google OAuth
Ensure your backend has the correct Google OAuth configuration:
```env
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
```

### 3. Run the Flutter App
```bash
flutter run
```

### 4. Test Authentication Flow
1. Tap "Continue with Google" on login screen
2. Complete Google OAuth flow
3. If profile incomplete, fill out profile completion form
4. Verify navigation to appropriate dashboard based on user role

### 5. Test Tourist Features
1. **My Tours**: Should load user's registered tours
2. **Search Tours**: Enter a valid join code to find tours
3. **Register**: Join a tour using the join code
4. **Unregister**: Cancel registration from My Tours

### 6. Test Provider Features
1. **Dashboard**: View provider statistics
2. **Create Tour**: Add new tour with all fields
3. **Manage Tours**: View and edit existing tours

## 🔧 Configuration Details

### API Service Configuration
```dart
// lib/config/app_config.dart
static const String apiBaseUrl = 'http://localhost:3000';

// lib/services/api_service.dart
baseUrl: '${AppConfig.apiBaseUrl}/api/v1'
```

### Authentication Headers
All authenticated requests automatically include:
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

### Error Handling
The app handles your backend's error format:
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Error message",
    "details": {}
  }
}
```

## 🐛 Troubleshooting

### Common Issues

#### 1. CORS Errors
If you see CORS errors, ensure your backend allows requests from the Flutter app:
```javascript
// In your backend CORS configuration
app.use(cors({
  origin: ['http://localhost:3000', 'http://10.0.2.2:3000'], // Android emulator
  credentials: true
}));
```

#### 2. Network Connection (Android Emulator)
For Android emulator, you might need to use `10.0.2.2` instead of `localhost`:
```dart
// Update if needed for Android emulator
static const String apiBaseUrl = 'http://10.0.2.2:3000';
```

#### 3. Google OAuth Issues
- Ensure your Google OAuth client is configured for the correct redirect URI
- Check that your backend's Google OAuth flow is working in browser first
- Verify the `idToken` is being sent correctly

#### 4. Token Refresh Issues
The app automatically handles token refresh. If issues persist:
- Check your backend's `/auth/refresh` endpoint
- Verify JWT token expiration times
- Clear app data and re-authenticate

### Debug Mode
Enable debug logging by adding to your API service:
```dart
_dio.interceptors.add(LogInterceptor(
  requestBody: true,
  responseBody: true,
));
```

## 📱 Testing Scenarios

### Tourist User Journey
1. **Login** → Google OAuth → Profile completion (if needed)
2. **Browse Tours** → Search by join code → View tour details
3. **Register** → Join tour → Confirm registration
4. **My Tours** → View registered tours → Manage registrations

### Provider Admin Journey
1. **Login** → Navigate to provider dashboard
2. **View Stats** → See tour statistics and registrations
3. **Create Tour** → Fill form → Save tour
4. **Manage Tours** → Edit existing tours → Update status

### System Admin Journey
1. **Login** → Navigate to system dashboard
2. **User Management** → View placeholder screen
3. **Provider Management** → View placeholder screen

## 🔄 Data Flow

### Authentication Flow
```
Flutter App → Google Sign-In → Backend /auth/google/verify → JWT Tokens → Store Locally
```

### Tour Registration Flow
```
Search Tour → Enter Join Code → Backend /tours/join → Registration Created → Update UI
```

### Tour Creation Flow
```
Provider Form → Validate Data → Backend /tours → Tour Created → Refresh List
```

## 📊 API Response Handling

### Success Response
```json
{
  "success": true,
  "data": { /* response data */ },
  "message": "Optional success message"
}
```

### Error Response
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error",
    "details": {}
  }
}
```

### Pagination Response
```json
{
  "success": true,
  "data": [ /* array of items */ ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 100,
    "pages": 10,
    "hasNext": true,
    "hasPrev": false
  }
}
```

## 🚀 Production Deployment

### Environment Configuration
For production deployment, update the API base URL:
```dart
// lib/config/app_config.dart
static const String apiBaseUrl = 'https://api.tourlicity.com';
```

### Security Considerations
- Use HTTPS in production
- Implement certificate pinning
- Store tokens securely (consider using flutter_secure_storage)
- Validate all user inputs

## 📝 Next Steps

### Immediate Testing
1. Start your backend server
2. Run the Flutter app
3. Test the complete authentication flow
4. Verify tour creation and registration

### Future Enhancements
1. **Real-time Updates**: WebSocket integration for live notifications
2. **Document Upload**: File upload functionality for tourist documents
3. **Push Notifications**: Firebase integration for tour updates
4. **Offline Support**: Local caching for offline functionality
5. **Advanced Search**: Filters and sorting for tour discovery

## 🤝 Support

If you encounter any issues during integration:
1. Check the console logs for detailed error messages
2. Verify your backend API is responding correctly
3. Test individual endpoints using Postman or curl
4. Ensure all required environment variables are set

The Flutter app is now fully configured to work with your backend API. All endpoints are mapped correctly, and the data models match your API response format.