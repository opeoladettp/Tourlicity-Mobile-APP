import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../models/notification.dart';
import '../../utils/logger.dart';
import '../../widgets/common/navigation_drawer.dart' as nav;
import '../../widgets/common/app_bar_actions.dart';
import '../../widgets/common/safe_bottom_padding.dart';
import '../../config/routes.dart';
import 'package:go_router/go_router.dart';

class NotificationManagementScreen extends StatefulWidget {
  const NotificationManagementScreen({super.key});

  @override
  State<NotificationManagementScreen> createState() =>
      _NotificationManagementScreenState();
}

class _NotificationManagementScreenState
    extends State<NotificationManagementScreen> {
  final NotificationService _notificationService = NotificationService();

  NotificationQueueStats? _queueStats;
  List<Map<String, dynamic>> _allSubscriptions = [];
  bool _isLoadingStats = true;
  bool _isLoadingSubscriptions = true;
  bool _isCleaningUp = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadQueueStats(),
      _loadAllSubscriptions(),
    ]);
  }

  Future<void> _loadQueueStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final stats = await _notificationService.getQueueStats();
      setState(() {
        _queueStats = stats;
      });
    } catch (e) {
      Logger.error('Failed to load queue stats: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading queue stats: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _loadAllSubscriptions() async {
    setState(() => _isLoadingSubscriptions = true);
    try {
      final subscriptions = await _notificationService.getAllSubscriptions();
      setState(() {
        _allSubscriptions = subscriptions;
      });
    } catch (e) {
      Logger.error('Failed to load subscriptions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading subscriptions: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingSubscriptions = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Management'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [
          const BothActions(),
        ],
      ),
      drawer: nav.NavigationDrawer(
        currentRoute: '/notification-management',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.broadcastNotification),
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.send, color: Colors.white),
        label: const Text('Send Notification', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SafeScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildQueueStatistics(),
              const SizedBox(height: 24),
              _buildSubscriptionOverview(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push(AppRoutes.broadcastNotification),
                    icon: const Icon(Icons.send),
                    label: const Text('Send Notification'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isCleaningUp ? null : _cleanupQueues,
                    icon: _isCleaningUp
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cleaning_services),
                    label: Text(_isCleaningUp ? 'Cleaning...' : 'Cleanup Queues'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueStatistics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Queue Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoadingStats)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_queueStats != null)
              _buildQueueStatsContent()
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'No queue statistics available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueStatsContent() {
    final stats = _queueStats!;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Email Queue',
                'Waiting: ${stats.email.waiting}',
                'Active: ${stats.email.active}',
                'Completed: ${stats.email.completed}',
                'Failed: ${stats.email.failed}',
                Icons.email,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Push Queue',
                'Waiting: ${stats.push.waiting}',
                'Active: ${stats.push.active}',
                'Completed: ${stats.push.completed}',
                'Failed: ${stats.push.failed}',
                Icons.notifications,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Last updated: ${_formatTimestamp(stats.timestamp)}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String waiting,
    String active,
    String completed,
    String failed,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(waiting, style: const TextStyle(fontSize: 12)),
          Text(active, style: const TextStyle(fontSize: 12)),
          Text(completed, style: const TextStyle(fontSize: 12)),
          Text(failed, style: const TextStyle(fontSize: 12, color: Colors.red)),
        ],
      ),
    );
  }

  Widget _buildSubscriptionOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Push Subscriptions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoadingSubscriptions)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_allSubscriptions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.notifications_off, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No push subscriptions found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildSubscriptionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionsList() {
    // Group subscriptions by device type
    final groupedSubscriptions = <String, List<Map<String, dynamic>>>{};
    for (final subscription in _allSubscriptions) {
      final deviceType = subscription['deviceType'] ?? 'unknown';
      groupedSubscriptions.putIfAbsent(deviceType, () => []).add(subscription);
    }

    return Column(
      children: [
        // Summary
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.info, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Total Subscriptions: ${_allSubscriptions.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Device type breakdown
        ...groupedSubscriptions.entries.map((entry) {
          final deviceType = entry.key;
          final subscriptions = entry.value;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(_getDeviceIcon(deviceType), size: 20),
                const SizedBox(width: 8),
                Text('${deviceType.toUpperCase()}: ${subscriptions.length}'),
              ],
            ),
          );
        }),
      ],
    );
  }

  IconData _getDeviceIcon(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'mobile':
        return Icons.phone_android;
      case 'desktop':
        return Icons.computer;
      case 'tablet':
        return Icons.tablet;
      default:
        return Icons.device_unknown;
    }
  }

  Future<void> _cleanupQueues() async {
    setState(() => _isCleaningUp = true);
    try {
      await _notificationService.cleanupQueues();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification queues cleaned up successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadQueueStats(); // Refresh stats after cleanup
      }
    } catch (e) {
      Logger.error('Failed to cleanup queues: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cleaning up queues: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isCleaningUp = false);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}