import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../services/broadcast_service.dart';
import '../../services/user_management_service.dart';
import '../../services/custom_tour_service.dart';
import '../../utils/logger.dart';
import '../../widgets/common/navigation_drawer.dart' as nav;
import '../../widgets/common/app_bar_actions.dart';
import '../../widgets/common/safe_bottom_padding.dart';
import '../../models/user.dart';
import '../../models/custom_tour.dart';


class BroadcastNotificationScreen extends StatefulWidget {
  const BroadcastNotificationScreen({super.key});

  @override
  State<BroadcastNotificationScreen> createState() =>
      _BroadcastNotificationScreenState();
}

class _BroadcastNotificationScreenState
    extends State<BroadcastNotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  final BroadcastService _broadcastService = BroadcastService();
  final UserManagementService _userService = UserManagementService();
  final CustomTourService _tourService = CustomTourService();

  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedRecipientType = 'tour_broadcast';
  String _selectedDirectRecipientType = 'all_users'; // Add this to track direct notification recipient type
  String? _selectedUserId;
  String? _selectedTourId;
  String _selectedUserRole = 'tourist';
  String _notificationType = 'system_announcement';
  bool _includeEmail = true;
  bool _isSending = false;

  List<User> _users = [];
  List<CustomTour> _tours = [];
  bool _isLoadingUsers = false;
  bool _isLoadingTours = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadTours();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final users = await _userService.getAllUsers();
      setState(() {
        _users = users;
      });
    } catch (e) {
      Logger.error('Failed to load users: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _loadTours() async {
    setState(() => _isLoadingTours = true);
    try {
      final tours = await _tourService.getAllCustomTours();
      setState(() {
        _tours = tours
            .where(
              (tour) => tour.status == 'published' || tour.status == 'active',
            )
            .toList();
      });
    } catch (e) {
      Logger.error('Failed to load tours: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading tours: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingTours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Broadcast Notification'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [const BothActions()],
      ),
      drawer: nav.NavigationDrawer(currentRoute: '/broadcast-notification'),
      body: SafeScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationTypeSelector(),
            const SizedBox(height: 24),
            _buildNotificationForm(),
            const SizedBox(height: 24),
            _buildRecipientSelection(),
            const SizedBox(height: 24),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'tour_broadcast',
                  label: Text('Tour Broadcast'),
                  icon: Icon(Icons.campaign),
                ),
                ButtonSegment(
                  value: 'direct_notification',
                  label: Text('Direct Notification'),
                  icon: Icon(Icons.notifications),
                ),
              ],
              selected: {_selectedRecipientType},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  _selectedRecipientType = selection.first;
                  _selectedUserId = null;
                  _selectedTourId = null;
                });
              },
            ),
            const SizedBox(height: 12),
            if (_selectedRecipientType == 'tour_broadcast')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  border: Border.all(
                    color: Colors.indigo.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.indigo),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tour broadcasts are sent to all registered participants and automatically trigger push notifications and emails.',
                        style: TextStyle(color: Colors.indigo),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Direct notifications are sent immediately to selected users via push notifications and optionally email.',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_selectedRecipientType == 'direct_notification')
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Notification Title',
                  border: OutlineInputBorder(),
                  hintText: 'Enter notification title',
                ),
                maxLength: 100,
              ),
            if (_selectedRecipientType == 'direct_notification')
              const SizedBox(height: 16),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: _selectedRecipientType == 'tour_broadcast'
                    ? 'Broadcast Message'
                    : 'Message',
                border: const OutlineInputBorder(),
                hintText: _selectedRecipientType == 'tour_broadcast'
                    ? 'Enter your message to tour participants'
                    : 'Enter your message here',
              ),
              maxLines: 4,
              maxLength: 500,
            ),
            const SizedBox(height: 16),
            if (_selectedRecipientType == 'direct_notification')
              DropdownButtonFormField<String>(
                initialValue: _notificationType,
                decoration: const InputDecoration(
                  labelText: 'Notification Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'system_announcement',
                    child: Text('System Announcement'),
                  ),
                  DropdownMenuItem(
                    value: 'tour_update',
                    child: Text('Tour Update'),
                  ),
                  DropdownMenuItem(
                    value: 'maintenance',
                    child: Text('Maintenance Notice'),
                  ),
                  DropdownMenuItem(
                    value: 'promotion',
                    child: Text('Promotion'),
                  ),
                  DropdownMenuItem(
                    value: 'urgent',
                    child: Text('Urgent Notice'),
                  ),
                  DropdownMenuItem(
                    value: 'general',
                    child: Text('General Information'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _notificationType = value;
                    });
                  }
                },
              ),
            if (_selectedRecipientType == 'direct_notification')
              const SizedBox(height: 16),
            if (_selectedRecipientType == 'direct_notification')
              SwitchListTile(
                title: const Text('Include Email Notification'),
                subtitle: const Text('Send notification via email as well'),
                value: _includeEmail,
                onChanged: (value) {
                  setState(() {
                    _includeEmail = value;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recipients',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_selectedRecipientType == 'tour_broadcast')
              _buildTourSelection()
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedDirectRecipientType,
                decoration: const InputDecoration(
                  labelText: 'Send To',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'all_users',
                    child: SizedBox(
                      width: double.infinity,
                      child: Text('All Users', overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'user_role',
                    child: SizedBox(
                      width: double.infinity,
                      child: Text('Specific User Role', overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'specific_user',
                    child: SizedBox(
                      width: double.infinity,
                      child: Text('Specific User', overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedDirectRecipientType = value;
                      _selectedUserId = null; // Reset user selection
                    });
                  }
                },
              ),
            const SizedBox(height: 16),
            if (_selectedRecipientType == 'direct_notification') ...[
              if (_selectedDirectRecipientType == 'user_role') _buildRoleSelection(),
              if (_selectedDirectRecipientType == 'specific_user')
                _buildUserSelection(),
            ],
            const SizedBox(height: 16),
            _buildRecipientSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildTourSelection() {
    if (_isLoadingTours) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_tours.isEmpty) {
      return Card(
        color: Colors.orange[50],
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text('No active tours available. Create a tour first.'),
              ),
            ],
          ),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedTourId,
      decoration: const InputDecoration(
        labelText: 'Select Tour',
        border: OutlineInputBorder(),
      ),
      hint: const Text('Choose a tour to broadcast to'),
      items: _tours.map((tour) {
        return DropdownMenuItem(
          value: tour.id,
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tour.tourName,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${tour.provider?.name ?? 'Unknown Provider'} • ${tour.statusDisplayName}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedTourId = value;
        });
      },
    );
  }

  Widget _buildRoleSelection() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedUserRole,
      decoration: const InputDecoration(
        labelText: 'User Role',
        border: OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem(
          value: 'tourist', 
          child: SizedBox(
            width: double.infinity,
            child: Text('Tourists', overflow: TextOverflow.ellipsis),
          ),
        ),
        DropdownMenuItem(
          value: 'provider_admin',
          child: SizedBox(
            width: double.infinity,
            child: Text('Provider Admins', overflow: TextOverflow.ellipsis),
          ),
        ),
        DropdownMenuItem(
          value: 'system_admin', 
          child: SizedBox(
            width: double.infinity,
            child: Text('System Admins', overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedUserRole = value;
          });
        }
      },
    );
  }

  Widget _buildUserSelection() {
    if (_isLoadingUsers) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_users.isEmpty) {
      return Card(
        color: Colors.orange[50],
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('No users available. Try refreshing the list.'),
            ],
          ),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedUserId,
      decoration: const InputDecoration(
        labelText: 'Select User',
        border: OutlineInputBorder(),
      ),
      hint: const Text('Choose a user'),
      items: _users.map((user) {
        return DropdownMenuItem(
          value: user.id,
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${user.firstName} ${user.lastName}',
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${user.email} (${user.userType})',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedUserId = value;
        });
      },
    );
  }

  Widget _buildRecipientSummary() {
    String summary;
    Color color;
    IconData icon;

    if (_selectedRecipientType == 'tour_broadcast') {
      if (_selectedTourId != null) {
        final tour = _tours.firstWhere((t) => t.id == _selectedTourId);
        summary =
            'Broadcast will be sent to all participants of "${tour.tourName}". '
            'Push notifications and emails will be sent automatically.';
        color = Colors.indigo;
        icon = Icons.campaign;
      } else {
        summary = 'Please select a tour to broadcast to';
        color = Colors.orange;
        icon = Icons.warning;
      }
    } else {
      // Direct notification logic
      switch (_selectedDirectRecipientType) {
        case 'all_users':
          summary = 'All users will receive this notification';
          color = Colors.blue;
          icon = Icons.people;
          break;
        case 'user_role':
          final roleCount = _users
              .where((u) => u.userType == _selectedUserRole)
              .length;
          summary =
              'All $_selectedUserRole users ($roleCount users) will receive this notification';
          color = Colors.green;
          icon = Icons.group;
          break;
        case 'specific_user':
          if (_selectedUserId != null) {
            final user = _users.firstWhere((u) => u.id == _selectedUserId);
            summary =
                '${user.firstName} ${user.lastName} (${user.email}) will receive this notification';
            color = Colors.purple;
            icon = Icons.person;
          } else {
            summary = 'Please select a user';
            color = Colors.orange;
            icon = Icons.warning;
          }
          break;
        default:
          summary = 'Unknown recipient type';
          color = Colors.red;
          icon = Icons.error;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              summary,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    bool canSend = _messageController.text.trim().isNotEmpty;

    if (_selectedRecipientType == 'tour_broadcast') {
      canSend = canSend && _selectedTourId != null;
    } else {
      canSend =
          canSend &&
          _titleController.text.trim().isNotEmpty &&
          (_selectedDirectRecipientType != 'specific_user' ||
              _selectedUserId != null);
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canSend && !_isSending ? _sendNotification : null,
        icon: _isSending
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(
                _selectedRecipientType == 'tour_broadcast'
                    ? Icons.campaign
                    : Icons.send,
              ),
        label: Text(
          _isSending
              ? 'Sending...'
              : _selectedRecipientType == 'tour_broadcast'
              ? 'Send Broadcast'
              : 'Send Notification',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _sendNotification() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a message'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedRecipientType == 'tour_broadcast' && _selectedTourId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a tour'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedRecipientType == 'direct_notification' &&
        _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title for direct notifications'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final message = _messageController.text.trim();

      if (_selectedRecipientType == 'tour_broadcast') {
        // Send tour broadcast - this automatically triggers notifications
        await _broadcastService.createAndPublishBroadcast(
          customTourId: _selectedTourId!,
          message: message,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Broadcast sent successfully! Notifications delivered automatically.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Send direct notification
        final title = _titleController.text.trim();

        switch (_selectedDirectRecipientType) {
          case 'all_users':
            // Send to all users by sending to each user type
            for (final userType in [
              'tourist',
              'provider_admin',
              'system_admin',
            ]) {
              await _notificationService.sendBulkNotifications(
                userType: userType,
                title: title,
                body: message,
                type: _notificationType,
                includeEmail: _includeEmail,
              );
            }
            break;

          case 'user_role':
            await _notificationService.sendBulkNotifications(
              userType: _selectedUserRole,
              title: title,
              body: message,
              type: _notificationType,
              includeEmail: _includeEmail,
            );
            break;

          case 'specific_user':
            if (_selectedUserId != null) {
              await _notificationService.sendNotificationToUser(
                userId: _selectedUserId!,
                title: title,
                body: message,
                type: _notificationType,
                includeEmail: _includeEmail,
              );
            }
            break;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification sent successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      // Clear the form
      _titleController.clear();
      _messageController.clear();
      setState(() {
        _selectedRecipientType = 'tour_broadcast';
        _selectedDirectRecipientType = 'all_users';
        _selectedUserId = null;
        _selectedTourId = null;
        _selectedUserRole = 'tourist';
        _notificationType = 'system_announcement';
        _includeEmail = true;
      });
    } catch (e) {
      Logger.error('Failed to send notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending notification: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }
}
