import '../models/notification.dart';
import '../utils/logger.dart';
import 'api_service.dart';

class NotificationService {
  final ApiService _apiService = ApiService();

  /// Get VAPID public key for push notifications
  Future<String> getVapidKey() async {
    try {
      final response = await _apiService.get('/notifications/vapid-key');

      if (response.statusCode == 200) {
        return response.data['vapidKey'] ?? response.data['publicKey'] ?? '';
      }
      throw Exception('Failed to get VAPID key');
    } catch (e) {
      Logger.error('Failed to get VAPID key: $e');
      rethrow;
    }
  }

  /// Subscribe to push notifications
  Future<String> subscribeToPushNotifications(
    PushSubscription subscription,
  ) async {
    try {
      final response = await _apiService.post(
        '/notifications/subscribe',
        data: subscription.toJson(),
      );

      if (response.statusCode == 200) {
        return response.data['subscription_id'] ?? 'subscribed';
      }
      throw Exception('Failed to subscribe to push notifications');
    } catch (e) {
      Logger.error('Failed to subscribe to push notifications: $e');
      rethrow;
    }
  }

  /// Unsubscribe from push notifications
  Future<void> unsubscribeFromPushNotifications() async {
    try {
      final response = await _apiService.post('/notifications/unsubscribe');

      if (response.statusCode != 200) {
        throw Exception('Failed to unsubscribe from push notifications');
      }
    } catch (e) {
      Logger.error('Failed to unsubscribe from push notifications: $e');
      rethrow;
    }
  }

  /// Get user's push subscriptions
  Future<List<Map<String, dynamic>>> getUserSubscriptions() async {
    try {
      final response = await _apiService.get('/notifications/subscriptions');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(
          response.data['subscriptions'] ?? [],
        );
      }
      throw Exception('Failed to get user subscriptions');
    } catch (e) {
      Logger.error('Failed to get user subscriptions: $e');
      rethrow;
    }
  }

  /// Send test notification
  Future<void> sendTestNotification() async {
    try {
      final response = await _apiService.post('/notifications/test');

      if (response.statusCode != 200) {
        throw Exception('Failed to send test notification');
      }
    } catch (e) {
      Logger.error('Failed to send test notification: $e');
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
      final response = await _apiService.post(
        '/notifications/send',
        data: {
          'userId': userId,
          'title': title,
          'body': body,
          'type': type,
          'includeEmail': includeEmail,
          if (data != null) 'data': data,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send notification');
      }
    } catch (e) {
      Logger.error('Failed to send notification to user: $e');
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
      final response = await _apiService.post(
        '/notifications/send-bulk',
        data: {
          'userType': userType,
          'title': title,
          'body': body,
          'type': type,
          'includeEmail': includeEmail,
          if (data != null) 'data': data,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send bulk notifications');
      }
    } catch (e) {
      Logger.error('Failed to send bulk notifications: $e');
      rethrow;
    }
  }

  /// Get notification queue statistics (System Admin only)
  Future<NotificationQueueStats> getQueueStats() async {
    try {
      final response = await _apiService.get('/notifications/queue-stats');

      if (response.statusCode == 200) {
        return NotificationQueueStats.fromJson(response.data);
      }
      throw Exception('Failed to get queue statistics');
    } catch (e) {
      Logger.error('Failed to get queue statistics: $e');
      rethrow;
    }
  }

  /// Clean up notification queues (System Admin only)
  Future<void> cleanupQueues() async {
    try {
      final response = await _apiService.post('/notifications/cleanup');

      if (response.statusCode != 200) {
        throw Exception('Failed to cleanup notification queues');
      }
    } catch (e) {
      Logger.error('Failed to cleanup notification queues: $e');
      rethrow;
    }
  }

  /// Get all subscriptions (System Admin only)
  Future<List<Map<String, dynamic>>> getAllSubscriptions() async {
    try {
      final response = await _apiService.get(
        '/notifications/all-subscriptions',
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(
          response.data['subscriptions'] ?? [],
        );
      }
      throw Exception('Failed to get all subscriptions');
    } catch (e) {
      Logger.error('Failed to get all subscriptions: $e');
      rethrow;
    }
  }
}
