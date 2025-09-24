import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../services/user_management_service.dart';
import '../../utils/logger.dart';
import '../../widgets/common/navigation_drawer.dart' as nav;
import '../../widgets/common/app_bar_actions.dart';
import '../../widgets/common/safe_bottom_padding.dart';
import '../../models/user.dart';

class BroadcastNotificationScreen extends StatefulWidget {
  const BroadcastNotificationScreen({super.key});

  @override
  State<BroadcastNotificationScreen> createState() =>
      _BroadcastNotificationScreenState();
}

class _BroadcastNotificationScreenState
    extends State<BroadcastNotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  final UserManagementService _userService = UserManagementService();

  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedRecipientType = 'all_users';
  String? _selectedUserId;
  String _selectedUserRole = 'tourist';
  String _notificationType = 'system_announcement';
  bool _includeEmail = true;
  bool _isSending = false;

  List<User> _users = [];
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Broadcast Notification'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [
          const BothActions(),
        ],
      ),
      drawer: nav.NavigationDrawer(
        currentRoute: '/broadcast-notification',
      ),
      body: SafeScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

  Widget _buildNotificationForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Notification Title',
                border: OutlineInputBorder(),
                hintText: 'Enter notification title',
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
                hintText: 'Enter your message here',
              ),
              maxLines: 4,
              maxLength: 500,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _notificationType,
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
            const SizedBox(height: 16),
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRecipientType,
              decoration: const InputDecoration(
                labelText: 'Send To',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'all_users',
                  child: Text('All Users'),
                ),
                DropdownMenuItem(
                  value: 'user_role',
                  child: Text('Specific User Role'),
                ),
                DropdownMenuItem(
                  value: 'specific_user',
                  child: Text('Specific User'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedRecipientType = value;
                    _selectedUserId = null; // Reset user selection
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            if (_selectedRecipientType == 'user_role') _buildRoleSelection(),
            if (_selectedRecipientType == 'specific_user') _buildUserSelection(),
            const SizedBox(height: 16),
            _buildRecipientSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelection() {
    return DropdownButtonFormField<String>(
      value: _selectedUserRole,
      decoration: const InputDecoration(
        labelText: 'User Role',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(
          value: 'tourist',
          child: Text('Tourists'),
        ),
        DropdownMenuItem(
          value: 'provider_admin',
          child: Text('Provider Admins'),
        ),
        DropdownMenuItem(
          value: 'system_admin',
          child: Text('System Admins'),
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
      value: _selectedUserId,
      decoration: const InputDecoration(
        labelText: 'Select User',
        border: OutlineInputBorder(),
      ),
      hint: const Text('Choose a user'),
      items: _users.map((user) {
        return DropdownMenuItem(
          value: user.id,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${user.firstName} ${user.lastName}'),
              Text(
                '${user.email} (${user.userType})',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
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

    switch (_selectedRecipientType) {
      case 'all_users':
        summary = 'All users will receive this notification';
        color = Colors.blue;
        icon = Icons.people;
        break;
      case 'user_role':
        final roleCount = _users.where((u) => u.userType == _selectedUserRole).length;
        summary = 'All $_selectedUserRole users ($roleCount users) will receive this notification';
        color = Colors.green;
        icon = Icons.group;
        break;
      case 'specific_user':
        if (_selectedUserId != null) {
          final user = _users.firstWhere((u) => u.id == _selectedUserId);
          summary = '${user.firstName} ${user.lastName} (${user.email}) will receive this notification';
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
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
    final canSend = _titleController.text.trim().isNotEmpty &&
        _messageController.text.trim().isNotEmpty &&
        (_selectedRecipientType != 'specific_user' || _selectedUserId != null);

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
            : const Icon(Icons.send),
        label: Text(_isSending ? 'Sending...' : 'Send Notification'),
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
    if (_titleController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final title = _titleController.text.trim();
      final message = _messageController.text.trim();

      switch (_selectedRecipientType) {
        case 'all_users':
          // Send to all users by sending to each user type
          for (final userType in ['tourist', 'provider_admin', 'system_admin']) {
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

        // Clear the form
        _titleController.clear();
        _messageController.clear();
        setState(() {
          _selectedRecipientType = 'all_users';
          _selectedUserId = null;
          _selectedUserRole = 'tourist';
          _notificationType = 'system_announcement';
          _includeEmail = true;
        });
      }
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