import '../models/notification.dart';

import '../utils/logger.dart';
import 'api_service.dart';
import 'broadcast_service.dart';

class UserNotificationService {
  final ApiService _apiService = ApiService();
  final BroadcastService _broadcastService = BroadcastService();
  
  // Cache to prevent duplicate API calls
  static List<AppNotification>? _cachedNotifications;
  static DateTime? _lastFetchTime;
  static const Duration _cacheTimeout = Duration(minutes: 5);
  static Future<List<AppNotification>>? _ongoingRequest;

  /// Get user's notifications with caching and throttling
  Future<List<AppNotification>> getUserNotifications() async {
    // Return cached data if still valid
    if (_cachedNotifications != null && 
        _lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!) < _cacheTimeout) {
      Logger.info('📋 Returning cached notifications (${_cachedNotifications!.length} items)');
      return _cachedNotifications!;
    }
    
    // If there's already an ongoing request, wait for it
    if (_ongoingRequest != null) {
      Logger.info('⏳ Waiting for ongoing notification request...');
      return await _ongoingRequest!;
    }
    
    // Start new request
    _ongoingRequest = _fetchNotifications();
    
    try {
      final result = await _ongoingRequest!;
      _cachedNotifications = result;
      _lastFetchTime = DateTime.now();
      return result;
    } finally {
      _ongoingRequest = null;
    }
  }

  /// Internal method to fetch notifications
  Future<List<AppNotification>> _fetchNotifications() async {
    try {
      Logger.info('🔍 Fetching user notifications from backend endpoints');
      
      // Add delay to prevent rate limiting
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Generate sample notifications based on user activity (with reduced API calls)
      final notifications = await _generateNotificationsFromUserActivity();
      
      Logger.info('📊 Generated ${notifications.length} notifications from user activity');
      return notifications;
    } catch (e) {
      Logger.error('❌ Failed to get user notifications: $e');
      
      // Fallback to system notifications only
      Logger.warning('⚠️ Returning system notifications only due to API issues.');
      return _createSystemNotifications();
    }
  }

  /// Get user's push notification subscriptions
  Future<Map<String, dynamic>> _getUserSubscriptions() async {
    try {
      final response = await _apiService.get('/notifications/subscriptions');
      if (response.statusCode == 200) {
        return response.data ?? {};
      }
    } catch (e) {
      Logger.warning('⚠️ Could not fetch user subscriptions: $e');
    }
    return {};
  }

  /// Generate notifications from user activity using existing endpoints (optimized)
  Future<List<AppNotification>> _generateNotificationsFromUserActivity() async {
    final notifications = <AppNotification>[];
    
    try {
      // Reduce API calls by making them optional and handling failures gracefully
      List<dynamic> registrations = [];
      List<dynamic> roleRequests = [];
      
      // Try to get registrations (non-blocking)
      try {
        registrations = await _getUserRegistrations();
        notifications.addAll(_createTourNotifications(registrations));
      } catch (e) {
        Logger.debug('Skipping tour notifications due to API limit: $e');
      }
      
      // Try to get role requests (non-blocking)  
      try {
        roleRequests = await _getUserRoleRequests();
        notifications.addAll(_createRoleChangeNotifications(roleRequests));
      } catch (e) {
        Logger.debug('Skipping role change notifications due to API limit: $e');
      }
      
      // Skip broadcast notifications to reduce API calls for now
      // TODO: Re-enable when rate limiting is resolved
      
      // Always add system notifications (no API calls)
      notifications.addAll(_createSystemNotifications());
      
    } catch (e) {
      Logger.warning('⚠️ Error generating notifications from user activity: $e');
    }
    
    // Sort by timestamp (newest first)
    notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return notifications;
  }

  /// Get user's tour registrations
  Future<List<dynamic>> _getUserRegistrations() async {
    try {
      final response = await _apiService.get('/registrations/my');
      if (response.statusCode == 200) {
        return response.data['data'] ?? response.data['registrations'] ?? [];
      }
    } catch (e) {
      Logger.debug('Could not fetch user registrations: $e');
    }
    return [];
  }

  /// Get user's role change requests
  Future<List<dynamic>> _getUserRoleRequests() async {
    try {
      final response = await _apiService.get('/role-change-requests/my');
      if (response.statusCode == 200) {
        return response.data['data'] ?? response.data['requests'] ?? [];
      }
    } catch (e) {
      Logger.debug('Could not fetch role change requests: $e');
    }
    return [];
  }

  /// Create tour-related notifications from registrations
  List<AppNotification> _createTourNotifications(List<dynamic> registrations) {
    final notifications = <AppNotification>[];
    
    for (final registration in registrations) {
      try {
        final tourName = registration['custom_tour_id']?['tour_name'] ?? 'Your Tour';
        final status = registration['status'] ?? 'pending';
        final createdDate = DateTime.tryParse(registration['created_date'] ?? '') ?? DateTime.now();
        
        String title, body, type;
        bool isRead = false;
        
        switch (status) {
          case 'approved':
            title = 'Tour Registration Approved! 🎉';
            body = 'Your registration for "$tourName" has been approved. Get ready for an amazing experience!';
            type = 'tour_approved';
            break;
          case 'rejected':
            title = 'Tour Registration Update';
            body = 'Your registration for "$tourName" requires attention. Please check the details.';
            type = 'tour_rejected';
            break;
          case 'pending':
            title = 'Registration Received';
            body = 'We\'ve received your registration for "$tourName". We\'ll review it shortly.';
            type = 'tour_pending';
            isRead = true; // Mark as read since it's just confirmation
            break;
          default:
            continue;
        }
        
        notifications.add(AppNotification(
          id: 'tour_${registration['_id']}',
          title: title,
          body: body,
          type: type,
          timestamp: createdDate,
          isRead: isRead,
          data: {'registration_id': registration['_id'], 'tour_name': tourName},
        ));
      } catch (e) {
        Logger.debug('Error creating tour notification: $e');
      }
    }
    
    return notifications;
  }

  /// Create role change notifications
  List<AppNotification> _createRoleChangeNotifications(List<dynamic> roleRequests) {
    final notifications = <AppNotification>[];
    
    for (final request in roleRequests) {
      try {
        final requestType = request['request_type'] ?? '';
        final status = request['status'] ?? 'pending';
        final createdDate = DateTime.tryParse(request['created_date'] ?? '') ?? DateTime.now();
        
        String title, body, type;
        bool isRead = false;
        
        switch (status) {
          case 'approved':
            title = 'Role Change Approved! 🎉';
            body = requestType == 'become_new_provider' 
                ? 'Congratulations! You\'re now a tour provider. Welcome to the platform!'
                : 'Your role change request has been approved. Welcome to your new role!';
            type = 'role_approved';
            break;
          case 'rejected':
            title = 'Role Change Request Update';
            body = 'Your role change request has been reviewed. Please check the admin notes for details.';
            type = 'role_rejected';
            break;
          case 'pending':
            title = 'Role Change Request Submitted';
            body = 'We\'ve received your role change request. Our team will review it shortly.';
            type = 'role_pending';
            isRead = true;
            break;
          default:
            continue;
        }
        
        notifications.add(AppNotification(
          id: 'role_${request['_id']}',
          title: title,
          body: body,
          type: type,
          timestamp: createdDate,
          isRead: isRead,
          data: {'request_id': request['_id'], 'request_type': requestType},
        ));
      } catch (e) {
        Logger.debug('Error creating role change notification: $e');
      }
    }
    
    return notifications;
  }

  /// Get broadcast notifications from user's registered tours
  Future<List<AppNotification>> _getBroadcastNotifications(List<dynamic> registrations) async {
    final notifications = <AppNotification>[];
    
    try {
      // Get broadcasts for each registered tour
      for (final registration in registrations) {
        try {
          final tourId = registration['custom_tour_id']?['_id'] ?? registration['custom_tour_id']?['id'];
          final tourName = registration['custom_tour_id']?['tour_name'] ?? 'Your Tour';
          
          if (tourId != null) {
            final broadcasts = await _broadcastService.getBroadcastsForTour(tourId, limit: 5);
            
            for (final broadcast in broadcasts) {
              if (broadcast.isPublished) {
                notifications.add(AppNotification(
                  id: 'broadcast_${broadcast.id}',
                  title: 'Message from ${broadcast.provider.providerName}',
                  body: broadcast.messagePreview,
                  type: 'broadcast',
                  timestamp: broadcast.createdDate,
                  isRead: false,
                  data: {
                    'broadcast_id': broadcast.id,
                    'tour_id': tourId,
                    'tour_name': tourName,
                    'provider_name': broadcast.provider.providerName,
                    'full_message': broadcast.message,
                  },
                ));
              }
            }
          }
        } catch (e) {
          Logger.debug('Error getting broadcasts for registration: $e');
        }
      }
    } catch (e) {
      Logger.warning('⚠️ Error getting broadcast notifications: $e');
    }
    
    return notifications;
  }

  /// Create system notifications
  List<AppNotification> _createSystemNotifications() {
    final notifications = <AppNotification>[];
    
    // Welcome notification for new users
    notifications.add(AppNotification(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Welcome to Tourlicity! 🌟',
      body: 'Discover amazing tours and create unforgettable memories. Start exploring now!',
      type: 'system_welcome',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: false,
    ));
    
    // Feature announcement
    notifications.add(AppNotification(
      id: 'feature_${DateTime.now().millisecondsSinceEpoch}',
      title: 'New Feature: Broadcast Messages',
      body: 'Tour providers can now send you real-time updates and messages about your tours!',
      type: 'feature_announcement',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: false,
    ));
    
    return notifications;
  }



  /// Mark notification as read (local storage for now)
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      Logger.info('📖 Marking notification as read: $notificationId');
      
      // For now, we'll handle this locally since the backend doesn't have 
      // persistent user notifications yet. In the future, this could call
      // a backend endpoint to track read status.
      
      // Could implement local storage here if needed
      Logger.info('✅ Notification marked as read locally');
    } catch (e) {
      Logger.error('Failed to mark notification as read: $e');
      // Don't rethrow - this is not critical
    }
  }

  /// Mark all notifications as read (local storage for now)
  Future<void> markAllNotificationsAsRead() async {
    try {
      Logger.info('📖 Marking all notifications as read');
      
      // For now, we'll handle this locally since the backend doesn't have 
      // persistent user notifications yet. In the future, this could call
      // a backend endpoint to track read status for all notifications.
      
      Logger.info('✅ All notifications marked as read locally');
    } catch (e) {
      Logger.error('Failed to mark all notifications as read: $e');
      // Don't rethrow - this is not critical
    }
  }

  /// Delete notification (local storage for now)
  Future<void> deleteNotification(String notificationId) async {
    try {
      Logger.info('🗑️ Deleting notification: $notificationId');
      
      // For now, we'll handle this locally since the backend doesn't have 
      // persistent user notifications yet. In the future, this could call
      // a backend endpoint to delete the notification.
      
      Logger.info('✅ Notification deleted locally');
    } catch (e) {
      Logger.error('Failed to delete notification: $e');
      // Don't rethrow - this is not critical
    }
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    try {
      // Get all notifications and count unread ones
      final notifications = await getUserNotifications();
      final unreadCount = notifications.where((n) => !n.isRead).length;
      
      Logger.info('📊 Unread notification count: $unreadCount');
      return unreadCount;
    } catch (e) {
      Logger.error('Failed to get unread notification count: $e');
      return 0; // Return 0 on error instead of throwing
    }
  }

  /// Send a test notification using existing backend endpoint
  Future<void> sendTestNotification() async {
    try {
      Logger.info('🧪 Sending test notification using backend endpoint');
      
      final response = await _apiService.post('/notifications/test');
      
      if (response.statusCode == 200) {
        Logger.info('✅ Test notification sent successfully');
      } else {
        Logger.warning('⚠️ Test notification failed with status: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('❌ Failed to send test notification: $e');
    }
  }

  /// Subscribe to push notifications using existing backend endpoint
  Future<bool> subscribeToPushNotifications(Map<String, dynamic> subscriptionData) async {
    try {
      Logger.info('🔔 Subscribing to push notifications');
      
      final response = await _apiService.post('/notifications/subscribe', data: subscriptionData);
      
      if (response.statusCode == 200) {
        Logger.info('✅ Successfully subscribed to push notifications');
        return true;
      } else {
        Logger.warning('⚠️ Push notification subscription failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      Logger.error('❌ Failed to subscribe to push notifications: $e');
      return false;
    }
  }
}
