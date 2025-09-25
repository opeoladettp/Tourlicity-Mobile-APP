import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/notification.dart';
import '../../services/user_notification_service.dart';
import '../../utils/logger.dart';
import '../../widgets/notifications/notification_display.dart';
import '../../widgets/common/navigation_drawer.dart' as nav;
import '../../widgets/common/app_bar_actions.dart';
import '../../widgets/common/safe_bottom_padding.dart';
import '../../config/routes.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final UserNotificationService _notificationService =
      UserNotificationService();

  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final notifications = await _notificationService.getUserNotifications();
      setState(() {
        _notifications = notifications;
      });
      Logger.info(
        '✅ Loaded ${notifications.length} notifications from database',
      );
    } catch (e) {
      Logger.error('❌ Failed to load notifications: $e');

      // Set empty list on error - no mock data
      setState(() {
        _notifications = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load notifications: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadNotifications,
            ),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<AppNotification> get _filteredNotifications {
    switch (_filter) {
      case 'unread':
        return _notifications.where((n) => !n.isRead).toList();
      case 'read':
        return _notifications.where((n) => n.isRead).toList();
      default:
        return _notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.dashboard),
          tooltip: 'Back to dashboard',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: () => _markAllAsRead('mark_all_read'),
            tooltip: 'Mark all as read',
          ),
          const SettingsOnlyActions(),
        ],
      ),
      drawer: nav.NavigationDrawer(currentRoute: '/notifications'),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadNotifications,
                    child: SafeBottomPadding(
                      child: _notifications.isEmpty
                          ? _buildEmptyState()
                          : NotificationDisplay(
                              notifications: _filteredNotifications,
                              onNotificationTap: _onNotificationTap,
                              onNotificationDismiss: _onNotificationDismiss,
                            ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          const Text('Filter: '),
          const SizedBox(width: 8),
          FilterChip(
            label: Text('All (${_notifications.length})'),
            selected: _filter == 'all',
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _filter = 'all';
                });
              }
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(
              'Unread (${_notifications.where((n) => !n.isRead).length})',
            ),
            selected: _filter == 'unread',
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _filter = 'unread';
                });
              }
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(
              'Read (${_notifications.where((n) => n.isRead).length})',
            ),
            selected: _filter == 'read',
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _filter = 'read';
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When you receive notifications, they\'ll appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _onNotificationTap(AppNotification notification) {
    // Mark as read if not already read
    if (!notification.isRead) {
      _markNotificationAsRead(notification);
    }

    // Handle navigation based on notification type
    _handleNotificationNavigation(notification);
  }

  Future<void> _markNotificationAsRead(AppNotification notification) async {
    try {
      await _notificationService.markNotificationAsRead(notification.id);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = notification.copyWith(isRead: true);
        }
      });
    } catch (e) {
      Logger.error('Failed to mark notification as read: $e');
      // Still update UI optimistically
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = notification.copyWith(isRead: true);
        }
      });
    }
  }

  void _onNotificationDismiss(AppNotification notification) {
    _deleteNotification(notification);
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    // Optimistically remove from UI
    setState(() {
      _notifications.removeWhere((n) => n.id == notification.id);
    });

    try {
      await _notificationService.deleteNotification(notification.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification dismissed'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                setState(() {
                  _notifications.add(notification);
                  _notifications.sort(
                    (a, b) => b.timestamp.compareTo(a.timestamp),
                  );
                });
              },
            ),
          ),
        );
      }
    } catch (e) {
      Logger.error('Failed to delete notification: $e');
      // Restore notification on error
      setState(() {
        _notifications.add(notification);
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to dismiss notification: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleNotificationNavigation(AppNotification notification) {
    final data = notification.data ?? {};

    switch (notification.type) {
      case 'tour_update':
      case 'tour_status_change':
      case 'tour_cancelled':
      case 'tour_rescheduled':
        _navigateToTourDetails(data);
        break;

      case 'tour_broadcast':
      case 'broadcast_message':
        _navigateToTourBroadcasts(data);
        break;

      case 'role_change_approved':
      case 'role_change_rejected':
      case 'role_change_pending':
        _navigateToRoleChangeManagement();
        break;

      case 'new_tour_template':
      case 'tour_template_update':
        _navigateToTourTemplates(data);
        break;

      case 'profile_update_required':
      case 'profile_incomplete':
        _navigateToProfileUpdate();
        break;

      case 'system_announcement':
      case 'maintenance_notice':
        // Show full announcement dialog for system messages
        _showNotificationDialog(notification);
        break;

      case 'tour_invitation':
      case 'tour_join_request':
        _navigateToTourSearch(data);
        break;

      case 'itinerary_update':
      case 'activity_added':
      case 'activity_cancelled':
        _navigateToTourItinerary(data);
        break;

      case 'payment_reminder':
      case 'payment_confirmed':
      case 'payment_failed':
        _navigateToMyTours(data);
        break;

      default:
        // Show notification details for unknown types
        _showNotificationDialog(notification);
    }
  }

  void _navigateToTourDetails(Map<String, dynamic> data) {
    final tourId = data['tour_id'] ?? data['tourId'];
    if (tourId != null) {
      // Navigate to tour management with specific tour ID
      _safeNavigate(
        '${AppRoutes.tourManagement}?id=$tourId',
        fallbackRoute: AppRoutes.myTours,
      );
    } else {
      // Navigate to my tours if no specific tour ID
      _safeNavigate(AppRoutes.myTours, fallbackRoute: AppRoutes.dashboard);
    }
  }

  void _navigateToTourBroadcasts(Map<String, dynamic> data) {
    final tourId = data['tour_id'] ?? data['tourId'];
    if (tourId != null) {
      // Navigate to tour broadcasts with tour filter
      _safeNavigate(
        '${AppRoutes.tourBroadcasts}?tourId=$tourId',
        fallbackRoute: AppRoutes.tourBroadcasts,
      );
    } else {
      // Navigate to general tour broadcasts
      _safeNavigate(
        AppRoutes.tourBroadcasts,
        fallbackRoute: AppRoutes.dashboard,
      );
    }
  }

  void _navigateToRoleChangeManagement() {
    // Navigate to role change management
    _safeNavigate(
      AppRoutes.roleChangeManagement,
      fallbackRoute: AppRoutes.dashboard,
    );
  }

  void _navigateToTourTemplates(Map<String, dynamic> data) {
    final templateId = data['template_id'] ?? data['templateId'];
    if (templateId != null) {
      // Navigate to specific template activities
      _safeNavigate(
        '${AppRoutes.tourTemplateActivities}/$templateId',
        fallbackRoute: AppRoutes.tourTemplateBrowse,
      );
    } else {
      // Navigate to tour template browse for tourists, management for admins
      _safeNavigate(
        AppRoutes.tourTemplateBrowse,
        fallbackRoute: AppRoutes.dashboard,
      );
    }
  }

  void _navigateToProfileUpdate() {
    _safeNavigate(AppRoutes.profileUpdate, fallbackRoute: AppRoutes.dashboard);
  }

  void _navigateToTourSearch(Map<String, dynamic> data) {
    final joinCode = data['join_code'] ?? data['joinCode'];
    if (joinCode != null) {
      // Navigate to tour search with pre-filled join code
      _safeNavigate(
        '${AppRoutes.tourSearch}?joinCode=$joinCode',
        fallbackRoute: AppRoutes.tourSearch,
      );
    } else {
      // Navigate to general tour search
      _safeNavigate(AppRoutes.tourSearch, fallbackRoute: AppRoutes.dashboard);
    }
  }

  void _navigateToTourItinerary(Map<String, dynamic> data) {
    final tourId = data['tour_id'] ?? data['tourId'];
    if (tourId != null) {
      // Navigate to tour itinerary view
      _safeNavigate(
        '${AppRoutes.tourItineraryView}?tourId=$tourId',
        fallbackRoute: AppRoutes.myTours,
      );
    } else {
      // Navigate to my tours if no specific tour ID
      _safeNavigate(AppRoutes.myTours, fallbackRoute: AppRoutes.dashboard);
    }
  }

  void _navigateToMyTours(Map<String, dynamic> data) {
    final tourId = data['tour_id'] ?? data['tourId'];
    if (tourId != null) {
      // Navigate to my tours with specific tour highlighted
      _safeNavigate(
        '${AppRoutes.myTours}?highlightTour=$tourId',
        fallbackRoute: AppRoutes.myTours,
      );
    } else {
      // Navigate to general my tours
      _safeNavigate(AppRoutes.myTours, fallbackRoute: AppRoutes.dashboard);
    }
  }

  void _showNotificationDialog(AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 16),
            Text(
              'Received: ${_formatFullTimestamp(notification.timestamp)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _markAllAsRead(String action) {
    if (action == 'mark_all_read') {
      _markAllNotificationsAsRead();
    }
  }

  Future<void> _markAllNotificationsAsRead() async {
    try {
      await _notificationService.markAllNotificationsAsRead();
      setState(() {
        _notifications = _notifications.map((notification) {
          return notification.copyWith(isRead: true);
        }).toList();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Logger.error('Failed to mark all notifications as read: $e');
      // Still update UI optimistically
      setState(() {
        _notifications = _notifications.map((notification) {
          return notification.copyWith(isRead: true);
        }).toList();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marked as read locally. Error: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  String _formatFullTimestamp(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} at ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  /// Safe navigation with error handling
  void _safeNavigate(String route, {String? fallbackRoute}) {
    try {
      context.push(route);
    } catch (e) {
      Logger.error('Navigation failed for route: $route, error: $e');

      // Try fallback route if provided
      if (fallbackRoute != null) {
        try {
          context.push(fallbackRoute);
        } catch (fallbackError) {
          Logger.error('Fallback navigation also failed: $fallbackError');
          _showNavigationErrorSnackBar(route);
        }
      } else {
        _showNavigationErrorSnackBar(route);
      }
    }
  }

  void _showNavigationErrorSnackBar(String route) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to navigate to $route'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Dashboard',
            textColor: Colors.white,
            onPressed: () => context.go(AppRoutes.dashboard),
          ),
        ),
      );
    }
  }

  /// Get user-friendly notification type display name
  String _getNotificationTypeDisplayName(String type) {
    switch (type) {
      case 'tour_update':
        return 'Tour Update';
      case 'tour_status_change':
        return 'Tour Status Change';
      case 'tour_cancelled':
        return 'Tour Cancelled';
      case 'tour_rescheduled':
        return 'Tour Rescheduled';
      case 'tour_broadcast':
        return 'Tour Broadcast';
      case 'broadcast_message':
        return 'Broadcast Message';
      case 'role_change_approved':
        return 'Role Change Approved';
      case 'role_change_rejected':
        return 'Role Change Rejected';
      case 'role_change_pending':
        return 'Role Change Pending';
      case 'new_tour_template':
        return 'New Tour Template';
      case 'tour_template_update':
        return 'Tour Template Update';
      case 'profile_update_required':
        return 'Profile Update Required';
      case 'profile_incomplete':
        return 'Profile Incomplete';
      case 'system_announcement':
        return 'System Announcement';
      case 'maintenance_notice':
        return 'Maintenance Notice';
      case 'tour_invitation':
        return 'Tour Invitation';
      case 'tour_join_request':
        return 'Tour Join Request';
      case 'itinerary_update':
        return 'Itinerary Update';
      case 'activity_added':
        return 'Activity Added';
      case 'activity_cancelled':
        return 'Activity Cancelled';
      case 'payment_reminder':
        return 'Payment Reminder';
      case 'payment_confirmed':
        return 'Payment Confirmed';
      case 'payment_failed':
        return 'Payment Failed';
      default:
        return type
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (word) => word.isNotEmpty
                  ? word[0].toUpperCase() + word.substring(1)
                  : word,
            )
            .join(' ');
    }
  }
}
