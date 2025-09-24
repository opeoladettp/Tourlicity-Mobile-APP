import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/routes.dart';
import '../../widgets/notifications/notification_display.dart';
import '../../models/notification.dart';
import '../../services/user_notification_service.dart';
import '../../utils/logger.dart';

class NotificationIcon extends StatefulWidget {
  const NotificationIcon({super.key});

  @override
  State<NotificationIcon> createState() => _NotificationIconState();
}

class _NotificationIconState extends State<NotificationIcon> {
  final UserNotificationService _notificationService = UserNotificationService();
  
  List<AppNotification> _notifications = [];
  bool _isLoading = false;

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
    } catch (e) {
      Logger.error('Failed to load notifications in icon: $e');
      
      // Fallback to mock data for the icon
      final mockNotifications = [
        AppNotification(
          id: '1',
          title: 'Welcome to Tourlicity!',
          body: 'Thank you for joining our platform.',
          type: 'system_announcement',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          isRead: false,
        ),
        AppNotification(
          id: '2',
          title: 'Tour Update',
          body: 'Your upcoming tour has been updated.',
          type: 'tour_update',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          isRead: true,
        ),
        AppNotification(
          id: '3',
          title: 'System Maintenance',
          body: 'Scheduled maintenance tonight.',
          type: 'maintenance',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          isRead: false,
        ),
      ];
      
      setState(() {
        _notifications = mockNotifications;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: NotificationBadge(
        count: _unreadCount,
        child: const Icon(Icons.notifications),
      ),
      tooltip: 'Notifications',
      onSelected: (value) {
        switch (value) {
          case 'view_all':
            context.push(AppRoutes.notifications);
            break;
          case 'mark_all_read':
            _markAllAsRead();
            break;
        }
      },
      itemBuilder: (context) {
        final recentNotifications = _notifications
            .where((n) => !n.isRead)
            .take(3)
            .toList();

        return [
          // Header
          PopupMenuItem<String>(
            enabled: false,
            child: Row(
              children: [
                const Icon(Icons.notifications, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                if (_unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const PopupMenuDivider(),
          
          // Recent notifications or empty state
          if (recentNotifications.isEmpty)
            const PopupMenuItem<String>(
              enabled: false,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.notifications_none, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'No new notifications',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            ...recentNotifications.map((notification) => PopupMenuItem<String>(
              enabled: false,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _getNotificationIcon(notification.type),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            notification.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: Text(
                        _formatTimestamp(notification.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
          
          if (recentNotifications.isNotEmpty) const PopupMenuDivider(),
          
          // Actions
          PopupMenuItem<String>(
            value: 'view_all',
            child: const Row(
              children: [
                Icon(Icons.list, size: 18),
                SizedBox(width: 8),
                Text('View All Notifications'),
              ],
            ),
          ),
          
          if (_unreadCount > 0)
            PopupMenuItem<String>(
              value: 'mark_all_read',
              child: const Row(
                children: [
                  Icon(Icons.mark_email_read, size: 18),
                  SizedBox(width: 8),
                  Text('Mark All as Read'),
                ],
              ),
            ),
          

        ];
      },
    );
  }

  Widget _getNotificationIcon(String type) {
    IconData iconData;
    Color color;

    switch (type) {
      case 'system_announcement':
        iconData = Icons.campaign;
        color = Colors.blue;
        break;
      case 'tour_update':
        iconData = Icons.tour;
        color = Colors.green;
        break;
      case 'maintenance':
        iconData = Icons.build;
        color = Colors.orange;
        break;
      case 'promotion':
        iconData = Icons.local_offer;
        color = Colors.purple;
        break;
      case 'urgent':
        iconData = Icons.priority_high;
        color = Colors.red;
        break;
      case 'general':
        iconData = Icons.info;
        color = Colors.grey;
        break;
      default:
        iconData = Icons.notifications;
        color = Colors.blue;
    }

    return Icon(iconData, color: color, size: 16);
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  Future<void> _markAllAsRead() async {
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
            duration: Duration(seconds: 2),
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
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}