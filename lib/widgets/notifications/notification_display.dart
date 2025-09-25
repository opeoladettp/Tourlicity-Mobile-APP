import 'package:flutter/material.dart';
import '../../models/notification.dart';

class NotificationDisplay extends StatelessWidget {
  final List<AppNotification> notifications;
  final Function(AppNotification)? onNotificationTap;
  final Function(AppNotification)? onNotificationDismiss;

  const NotificationDisplay({
    super.key,
    required this.notifications,
    this.onNotificationTap,
    this.onNotificationDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No notifications',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationCard(context, notification);
      },
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotification notification) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          color: Colors.red,
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (direction) {
          onNotificationDismiss?.call(notification);
        },
        child: ListTile(
          leading: _getNotificationIcon(notification.type),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.body),
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(notification.timestamp),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          trailing: notification.isRead
              ? null
              : Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
          onTap: () => onNotificationTap?.call(notification),
        ),
      ),
    );
  }

  Widget _getNotificationIcon(String type) {
    IconData iconData;
    Color color;

    switch (type) {
      case 'broadcast':
        iconData = Icons.campaign;
        color = Colors.indigo;
        break;
      case 'tour_approved':
        iconData = Icons.check_circle;
        color = Colors.green;
        break;
      case 'tour_rejected':
        iconData = Icons.cancel;
        color = Colors.red;
        break;
      case 'tour_pending':
        iconData = Icons.pending;
        color = Colors.orange;
        break;
      case 'role_approved':
        iconData = Icons.verified_user;
        color = Colors.green;
        break;
      case 'role_rejected':
        iconData = Icons.person_remove;
        color = Colors.red;
        break;
      case 'role_pending':
        iconData = Icons.person_add;
        color = Colors.orange;
        break;
      case 'system_announcement':
        iconData = Icons.campaign;
        color = Colors.blue;
        break;
      case 'system_welcome':
        iconData = Icons.waving_hand;
        color = Colors.purple;
        break;
      case 'feature_announcement':
        iconData = Icons.new_releases;
        color = Colors.teal;
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

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.1),
      child: Icon(iconData, color: color, size: 20),
    );
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
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

class NotificationBadge extends StatelessWidget {
  final int count;
  final Widget child;

  const NotificationBadge({
    super.key,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (count > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}