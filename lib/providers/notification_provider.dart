import 'package:flutter/foundation.dart';
import '../services/mongodb_push_notification_service.dart';
import '../models/notification.dart';
import '../utils/logger.dart';

class NotificationProvider with ChangeNotifier {
  final MongoDBPushNotificationService _mongoDBService = MongoDBPushNotificationService();
  
  String _notificationMethod = 'mongodb'; // Using MongoDB backend exclusively

  bool _isInitialized = false;
  bool _pushNotificationsEnabled = true;
  bool _emailNotificationsEnabled = true;
  bool _tourRemindersEnabled = true;
  bool _isLoading = false;
  String? _error;
  String? _subscriptionId;
  String? _vapidKey;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;
  bool get emailNotificationsEnabled => _emailNotificationsEnabled;
  bool get tourRemindersEnabled => _tourRemindersEnabled;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get subscriptionId => _subscriptionId;
  String? get vapidKey => _vapidKey;
  String get notificationMethod => _notificationMethod;

  /// Initialize notifications using MongoDB backend
  Future<void> initialize({String? userId}) async {
    if (_isInitialized) return;

    _setLoading(true);
    try {
      await _mongoDBService.initialize();
      _vapidKey = _mongoDBService.vapidKey;
      _isInitialized = _mongoDBService.isInitialized;
      
      if (_isInitialized) {
        Logger.info('✅ MongoDB backend notifications initialized');
      } else {
        throw Exception('Failed to initialize MongoDB notifications');
      }
    } catch (e) {
      Logger.error('❌ MongoDB notification initialization failed: $e');
      _setError('Failed to initialize notifications: $e');
      _isInitialized = false;
    } finally {
      _setLoading(false);
    }
  }

  /// Subscribe to push notifications via MongoDB backend
  Future<void> subscribeToPushNotifications({
    required String endpoint,
    required String p256dh,
    required String auth,
    String? userAgent,
    String? deviceType,
    String? browser,
  }) async {
    _setLoading(true);
    try {
      _subscriptionId = await _mongoDBService.subscribe(
        endpoint: endpoint,
        p256dh: p256dh,
        auth: auth,
        userAgent: userAgent,
        deviceType: deviceType,
        browser: browser,
      );
      _pushNotificationsEnabled = true;
      _clearError();
      Logger.info('🔔 Push notifications subscribed via MongoDB backend');
    } catch (e) {
      _setError('Failed to subscribe to push notifications: $e');
      Logger.error('❌ Failed to subscribe to push notifications: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Toggle push notifications
  Future<void> togglePushNotifications(bool enabled) async {
    _setLoading(true);
    try {
      if (enabled) {
        // For enabling, you'll need to call subscribeToPushNotifications with actual subscription data
        Logger.info('🔔 Push notifications enabled (subscription required)');
      } else {
        await _mongoDBService.unsubscribe();
        _subscriptionId = null;
        Logger.info('🔔 Push notifications disabled via MongoDB backend');
      }
      
      _pushNotificationsEnabled = enabled;
      _clearError();
    } catch (e) {
      _setError('Failed to toggle push notifications: $e');
      Logger.error('❌ Failed to toggle push notifications: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Toggle email notifications
  Future<void> toggleEmailNotifications(bool enabled) async {
    _emailNotificationsEnabled = enabled;
    Logger.info('📧 Email notifications ${enabled ? 'enabled' : 'disabled'}');
    notifyListeners();
    // Note: Email preferences are handled server-side in your MongoDB backend
  }

  /// Toggle tour reminders
  Future<void> toggleTourReminders(bool enabled) async {
    _tourRemindersEnabled = enabled;
    Logger.info('⏰ Tour reminders ${enabled ? 'enabled' : 'disabled'}');
    notifyListeners();
    // Note: Tour reminder preferences are handled server-side in your MongoDB backend
  }

  /// Send test notification via MongoDB backend
  Future<void> sendTestNotification() async {
    _setLoading(true);
    try {
      await _mongoDBService.sendTestNotification();
      Logger.info('✅ Test notification sent successfully via MongoDB backend');
    } catch (e) {
      _setError('Failed to send test notification: $e');
      Logger.error('❌ Failed to send test notification: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Send notification to user (Admin/Provider only)
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    bool includeEmail = false,
    Map<String, dynamic>? data,
  }) async {
    _setLoading(true);
    try {
      await _mongoDBService.sendNotificationToUser(
        userId: userId,
        title: title,
        body: body,
        type: type,
        includeEmail: includeEmail,
        data: data,
      );
      Logger.info('✅ Notification sent to user successfully via MongoDB backend');
    } catch (e) {
      _setError('Failed to send notification: $e');
      Logger.error('❌ Failed to send notification to user: $e');
      rethrow;
    } finally {
      _setLoading(false);
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
    _setLoading(true);
    try {
      await _mongoDBService.sendBulkNotifications(
        userType: userType,
        title: title,
        body: body,
        type: type,
        includeEmail: includeEmail,
        data: data,
      );
      Logger.info('✅ Bulk notifications sent successfully via MongoDB backend');
    } catch (e) {
      _setError('Failed to send bulk notifications: $e');
      Logger.error('❌ Failed to send bulk notifications: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Get notification queue statistics (System Admin only)
  Future<NotificationQueueStats> getQueueStats() async {
    try {
      return await _mongoDBService.getQueueStats();
    } catch (e) {
      Logger.error('❌ Failed to get queue stats: $e');
      rethrow;
    }
  }

  /// Clean up notification queues (System Admin only)
  Future<void> cleanupQueues() async {
    try {
      await _mongoDBService.cleanupQueues();
      Logger.info('✅ Notification queues cleaned up via MongoDB backend');
    } catch (e) {
      Logger.error('❌ Failed to cleanup queues: $e');
      rethrow;
    }
  }

  /// Get all subscriptions (System Admin only)
  Future<List<Map<String, dynamic>>> getAllSubscriptions() async {
    try {
      return await _mongoDBService.getAllSubscriptions();
    } catch (e) {
      Logger.error('❌ Failed to get all subscriptions: $e');
      return [];
    }
  }

  /// Get user's subscriptions
  Future<List<Map<String, dynamic>>> getUserSubscriptions() async {
    try {
      return await _mongoDBService.getUserSubscriptions();
    } catch (e) {
      Logger.error('❌ Failed to get user subscriptions: $e');
      return [];
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}