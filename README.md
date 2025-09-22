# Tourlicity Mobile App

A modern Flutter mobile application for tour management with role-based access control.

## Features

### Authentication
- Google OAuth integration
- JWT token management
- Profile completion flow
- Role-based navigation

### User Roles

#### Tourist
- View registered tours
- Search tours by join code
- Register/unregister for tours
- View tour details and status

#### Provider Administrator
- Dashboard with statistics
- Create and manage tours
- View tour registrations
- Tour status management

#### System Administrator
- System-wide dashboard
- User management (placeholder)
- Provider management (placeholder)
- Tour template management (placeholder)

## Architecture

### Folder Structure
```
lib/
├── config/
│   └── routes.dart              # GoRouter configuration
├── models/
│   ├── user.dart               # User data model
│   ├── tour.dart               # Tour data model
│   ├── registration.dart       # Registration data model
│   └── provider.dart           # Provider data model
├── providers/
│   ├── auth_provider.dart      # Authentication state management
│   └── tour_provider.dart      # Tour state management
├── services/
│   ├── api_service.dart        # HTTP client with JWT handling
│   ├── auth_service.dart       # Authentication API calls
│   └── tour_service.dart       # Tour-related API calls
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── profile_completion_screen.dart
│   ├── tourist/
│   │   ├── my_tours_screen.dart
│   │   └── tour_search_screen.dart
│   ├── provider/
│   │   ├── provider_dashboard_screen.dart
│   │   └── tour_management_screen.dart
│   └── system/
│       ├── system_dashboard_screen.dart
│       ├── user_management_screen.dart
│       └── provider_management_screen.dart
├── widgets/
│   └── common/
│       ├── loading_overlay.dart
│       └── error_message.dart
└── main.dart
```

### State Management
- **Provider**: Used for state management across the app
- **AuthProvider**: Manages authentication state and user data
- **TourProvider**: Manages tour data and operations

### API Integration
- **Dio**: HTTP client for API calls
- **JWT Authentication**: Automatic token handling in API requests
- **Error Handling**: Comprehensive error handling with user feedback

## Setup Instructions

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio / VS Code
- Google Cloud Console project (for Google Sign-In)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd tourlicity
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Google Sign-In**
   - Create a project in Google Cloud Console
   - Enable Google Sign-In API
   - Configure OAuth consent screen
   - Add your app's SHA-1 fingerprint for Android
   - Download and place `google-services.json` in `android/app/`
   - For iOS, download and place `GoogleService-Info.plist` in `ios/Runner/`

4. **Update API Base URL**
   - Open `lib/services/api_service.dart`
   - Update the `baseUrl` constant with your backend API URL

5. **Run the app**
   ```bash
   flutter run
   ```

## API Endpoints

The app expects the following API endpoints:

### Authentication
- `POST /auth/google/verify` - Verify Google ID token
- `GET /auth/me` - Get current user profile
- `PUT /auth/profile` - Update user profile

### Tours
- `GET /tours/my-tours` - Get user's registered tours
- `GET /tours/search?join_code=CODE` - Search tour by join code
- `POST /tours/{id}/register` - Register for a tour
- `DELETE /tours/{id}/unregister` - Unregister from a tour
- `GET /tours/provider-tours` - Get provider's tours
- `POST /tours` - Create new tour
- `PUT /tours/{id}` - Update tour
- `DELETE /tours/{id}` - Delete tour

### Dashboard
- `GET /dashboard/provider-stats` - Get provider statistics

## Configuration

### Environment Variables
Update the following in your code:
- API base URL in `lib/services/api_service.dart`
- Google Sign-In configuration in platform-specific files

### Theme
The app uses Material 3 design with a custom color scheme based on indigo (#6366F1).

## Development Notes

### Adding New Features
1. Create models in `lib/models/`
2. Add API service methods in `lib/services/`
3. Create or update providers in `lib/providers/`
4. Build UI screens in `lib/screens/`
5. Add routes in `lib/config/routes.dart`

### Error Handling
- All API calls include comprehensive error handling
- User-friendly error messages are displayed
- Loading states are managed consistently

### Security
- JWT tokens are stored securely using SharedPreferences
- Automatic token refresh on API calls
- Role-based access control for navigation

## Testing

Run tests with:
```bash
flutter test
```

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License.
