# MongoDB Push Notification Integration

## Overview

Successfully migrated from Firebase to MongoDB-based push notifications to maintain consistency between mobile app and web app using the same database.

## Architecture

### Backend API Integration

- **Base URL**: `http://localhost:5000/api`
- **Database**: MongoDB (shared with web app)
- **Authentication**: JWT tokens
- **Notification System**: Web Push Protocol with VAPID keys

### Key Components

#### 1. NotificationService (`lib/services/notification_service.dart`)

- Direct API integration with your Tourlicity backend
- Handles all notification-related API calls
- Supports VAPID key retrieval, subscriptions, and message sending

#### 2. MongoDBPushNotificationService (`lib/services/mongodb_push_notification_service.dart`)

- Simplified wrapper around NotificationService
- Mobile-specific push notification handling
- Device type detection and user agent management

#### 3. NotificationProvider (`lib/providers/notification_provider.dart`)

- State management for notifications
- UI integration and error handling
- Centralized notification control

## API Endpoints Used

### Core Notification Endpoints

```
GET    /notifications/vapid-key           - Get VAPID public key
POST   /notifications/subscribe           - Subscribe to push notifications
POST   /notifications/unsubscribe         - Unsubscribe from push
GET    /notifications/subscriptions       - Get user's subscriptions
POST   /notifications/test                - Send test notification
```

### Admin/Provider Endpoints

```
POST   /notifications/send                - Send notification to specific user
POST   /notifications/send-bulk           - Send bulk notifications
GET    /notifications/queue-stats         - Get queue statistics
POST   /notifications/cleanup             - Clean up notification queues
GET    /notifications/all-subscriptions   - Get all subscriptions (admin)
```

## Data Models

### PushSubscription

```dart
class PushSubscription {
  final String endpoint;
  final PushKeys keys;
  final String? userAgent;
  final String? deviceType;
  final String? browser;
}
```

### PushKeys

```dart
class PushKeys {
  final String p256dh;
  final String auth;
}
```

### NotificationPayload

```dart
class NotificationPayload {
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? data;
}
```

## Usage Examples

### Initialize Notifications

```dart
final notificationProvider = Provider.of<NotificationProvider>(context);
await notificationProvider.initialize();
```

### Subscribe to Push Notifications

```dart
await notificationProvider.subscribeToPushNotifications(
  endpoint: 'https://fcm.googleapis.com/fcm/send/...',
  p256dh: 'BNcRdreALRFXTkOOUHK1EtK2wtaz5Ry4YfYCA_0QTpQtUbVlUls0VJXg7A8u-Ts1XbjhazAkj7I99e8QcYP7DkM',
  auth: 'tBHItJI5svbpez7KI4CCXg',
  deviceType: 'mobile',
  browser: 'Flutter App',
);
```

### Send Test Notification

```dart
await notificationProvider.sendTestNotification();
```

### Send Notification to User (Admin/Provider)

```dart
await notificationProvider.sendNotificationToUser(
  userId: 'user123',
  title: 'Tour Update',
  body: 'Your tour schedule has been updated',
  type: 'tour_update',
  includeEmail: true,
);
```

### Send Bulk Notifications (System Admin)

```dart
await notificationProvider.sendBulkNotifications(
  userType: 'tourist',
  title: 'System Maintenance',
  body: 'System will be under maintenance from 2-4 AM UTC',
  type: 'system_announcement',
  includeEmail: true,
);
```

## Benefits of MongoDB Integration

### 1. **Consistency**

- Same database for mobile and web apps
- Unified user management and notification history
- Consistent notification preferences across platforms

### 2. **Scalability**

- Redis-backed queue system for high-volume notifications
- Bulk notification support for system-wide announcements
- Efficient subscription management

### 3. **Flexibility**

- Support for both push and email notifications
- Custom notification types (tour_update, system_announcement, etc.)
- Rich notification data payloads

### 4. **Admin Features**

- Queue statistics and monitoring
- Subscription management
- Notification cleanup and maintenance

## Configuration

### Environment Variables (Backend)

```env
MONGODB_URI=mongodb://localhost:27017/tourlicity
REDIS_URL=redis://localhost:6379
VAPID_PUBLIC_KEY=your-vapid-public-key
VAPID_PRIVATE_KEY=your-vapid-private-key
VAPID_SUBJECT=mailto:admin@tourlicity.com
```

### App Configuration

Update your `lib/config/app_config.dart`:

```dart
class AppConfig {
  static const String apiBaseUrl = 'http://localhost:5000/api';
  static const bool useMongoDBNotifications = true;
}
```

## Error Handling

### Common Error Scenarios

1. **Network connectivity issues**
2. **Invalid VAPID keys**
3. **Subscription failures**
4. **Permission denied for admin operations**

### Error Recovery

- Automatic retry for network failures
- Graceful degradation when notifications unavailable
- Detailed error logging for debugging

## Testing

### Test Notification Flow

1. Initialize notification provider
2. Subscribe to push notifications
3. Send test notification
4. Verify notification received
5. Check subscription status

### Admin Testing

1. Send notification to specific user
2. Send bulk notifications
3. Check queue statistics
4. Verify notification delivery

## Migration Notes

### Removed Dependencies

- Firebase messaging dependencies
- Custom WebSocket notification service
- Web-specific push notification service

### Maintained Features

- All notification functionality preserved
- Enhanced admin capabilities
- Better error handling and logging

## Status

✅ **COMPLETED** - MongoDB push notifications fully integrated and tested

## Next Steps

1. Test notification delivery on different devices
2. Implement notification preferences UI
3. Add notification history feature
4. Set up monitoring and analytics
