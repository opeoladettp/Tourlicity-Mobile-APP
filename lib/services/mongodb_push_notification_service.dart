import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import '../utils/logger.dart';

/// MongoDB-based push notification service for mobile apps
/// This service integrates with your Tourlicity backend API
class MongoDBPushNotificationService {
  final NotificationService _notificationService = NotificationService();

  bool _isInitialized = false;
  String? _vapidKey;
  String? _subscriptionId;

  bool get isInitialized => _isInitialized;
  String? get vapidKey => _vapidKey;
  String? get subscriptionId => _subscriptionId;

  /// Initialize the MongoDB push notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Get VAPID key from your backend
      _vapidKey = await _notificationService.getVapidKey();

      if (_vapidKey != null && _vapidKey!.isNotEmpty) {
        _isInitialized = true;
        Logger.info('✅ MongoDB push notifications initialized');
      } else {
        throw Exception('Failed to get VAPID key from backend');
      }
    } catch (e) {
      Logger.error('❌ Failed to initialize MongoDB push notifications: $e');
      rethrow;
    }
  }

  /// Subscribe to push notifications
  Future<String> subscribe({
    required String endpoint,
    required String p256dh,
    required String auth,
    String? userAgent,
    String? deviceType,
    String? browser,
  }) async {
    try {
      final subscription = PushSubscription(
        endpoint: endpoint,
        keys: PushKeys(p256dh: p256dh, auth: auth),
        userAgent: userAgent ?? _getDefaultUserAgent(),
        deviceType: deviceType ?? _getDeviceType(),
        browser: browser ?? 'Flutter App',
      );

      _subscriptionId = await _notificationService.subscribeToPushNotifications(
        subscription,
      );
      Logger.info('✅ Subscribed to MongoDB push notifications');
      return _subscriptionId!;
    } catch (e) {
      Logger.error('❌ Failed to subscribe to push notifications: $e');
      rethrow;
    }
  }

  /// Unsubscribe from push notifications
  Future<void> unsubscribe() async {
    try {
      await _notificationService.unsubscribeFromPushNotifications();
      _subscriptionId = null;
      Logger.info('✅ Unsubscribed from MongoDB push notifications');
    } catch (e) {
      Logger.error('❌ Failed to unsubscribe from push notifications: $e');
      rethrow;
    }
  }

  /// Send test notification
  Future<void> sendTestNotification() async {
    try {
      await _notificationService.sendTestNotification();
      Logger.info('✅ Test notification sent via MongoDB backend');
    } catch (e) {
      Logger.error('❌ Failed to send test notification: $e');
      rethrow;
    }
  }

  /// Send notification to specific user (Admin/Provider only)
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    bool includeEmail = false,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _notificationService.sendNotificationToUser(
        userId: userId,
        title: title,
        body: body,
        type: type,
        includeEmail: includeEmail,
        data: data,
      );
      Logger.info('✅ Notification sent to user via MongoDB backend');
    } catch (e) {
      Logger.error('❌ Failed to send notification to user: $e');
      rethrow;
    }
  }

  /// Send bulk notifications (System Admin only)
  Future<void> sendBulkNotifications({
    required String userType,
    required String title,
    required String body,
    required String type,
    bool includeEmail = false,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _notificationService.sendBulkNotifications(
        userType: userType,
        title: title,
        body: body,
        type: type,
        includeEmail: includeEmail,
        data: data,
      );
      Logger.info('✅ Bulk notifications sent via MongoDB backend');
    } catch (e) {
      Logger.error('❌ Failed to send bulk notifications: $e');
      rethrow;
    }
  }

  /// Get user's subscriptions
  Future<List<Map<String, dynamic>>> getUserSubscriptions() async {
    try {
      return await _notificationService.getUserSubscriptions();
    } catch (e) {
      Logger.error('❌ Failed to get user subscriptions: $e');
      return [];
    }
  }

  /// Get notification queue statistics (System Admin only)
  Future<NotificationQueueStats> getQueueStats() async {
    try {
      return await _notificationService.getQueueStats();
    } catch (e) {
      Logger.error('❌ Failed to get queue statistics: $e');
      rethrow;
    }
  }

  /// Clean up notification queues (System Admin only)
  Future<void> cleanupQueues() async {
    try {
      await _notificationService.cleanupQueues();
      Logger.info('✅ Notification queues cleaned up');
    } catch (e) {
      Logger.error('❌ Failed to cleanup notification queues: $e');
      rethrow;
    }
  }

  /// Get all subscriptions (System Admin only)
  Future<List<Map<String, dynamic>>> getAllSubscriptions() async {
    try {
      return await _notificationService.getAllSubscriptions();
    } catch (e) {
      Logger.error('❌ Failed to get all subscriptions: $e');
      return [];
    }
  }

  String _getDefaultUserAgent() {
    if (kIsWeb) {
      return 'Tourlicity Web App';
    } else {
      return 'Tourlicity Mobile App';
    }
  }

  String _getDeviceType() {
    if (kIsWeb) {
      return 'web';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ios';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'android';
    } else {
      return 'mobile';
    }
  }
}
