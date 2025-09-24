import '../models/notification.dart';
import '../utils/logger.dart';
import 'api_service.dart';

class UserNotificationService {
  final ApiService _apiService = ApiService();

  /// Get user's notifications
  Future<List<AppNotification>> getUserNotifications() async {
    try {
      final response = await _apiService.get('/notifications/my');

      if (response.statusCode == 200) {
        final List<dynamic> data =
            response.data['notifications'] ?? response.data['data'] ?? [];
        return data.map((json) => AppNotification.fromJson(json)).toList();
      }
      throw Exception('Failed to load user notifications');
    } catch (e) {
      Logger.error('Failed to get user notifications: $e');
      rethrow;
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final response = await _apiService.put(
        '/notifications/$notificationId/read',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark notification as read');
      }
    } catch (e) {
      Logger.error('Failed to mark notification as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    try {
      final response = await _apiService.put('/notifications/mark-all-read');

      if (response.statusCode != 200) {
        throw Exception('Failed to mark all notifications as read');
      }
    } catch (e) {
      Logger.error('Failed to mark all notifications as read: $e');
      rethrow;
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final response = await _apiService.delete(
        '/notifications/$notificationId',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete notification');
      }
    } catch (e) {
      Logger.error('Failed to delete notification: $e');
      rethrow;
    }
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    try {
      final response = await _apiService.get('/notifications/unread-count');

      if (response.statusCode == 200) {
        return response.data['count'] ?? 0;
      }
      throw Exception('Failed to get unread notification count');
    } catch (e) {
      Logger.error('Failed to get unread notification count: $e');
      return 0; // Return 0 on error instead of throwing
    }
  }
}
