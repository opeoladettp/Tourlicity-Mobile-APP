import 'package:flutter/material.dart';
import '../../services/role_change_service.dart';
import '../../models/role_change_request.dart';
import '../../utils/logger.dart';
import '../../config/routes.dart';
import '../../widgets/common/navigation_drawer.dart' as nav;
import '../../widgets/common/app_bar_actions.dart';

class RoleChangeManagementScreen extends StatefulWidget {
  const RoleChangeManagementScreen({super.key});

  @override
  State<RoleChangeManagementScreen> createState() => _RoleChangeManagementScreenState();
}

class _RoleChangeManagementScreenState extends State<RoleChangeManagementScreen> {
  final RoleChangeService _roleChangeService = RoleChangeService();
  
  List<RoleChangeRequest> _requests = [];
  bool _isLoading = true;
  String _selectedStatus = 'all';
  
  final List<Map<String, String>> _statusFilters = [
    {'value': 'all', 'label': 'All Requests'},
    {'value': 'pending', 'label': 'Pending'},
    {'value': 'approved', 'label': 'Approved'},
    {'value': 'rejected', 'label': 'Rejected'},
  ];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    
    try {
      final requests = await _roleChangeService.getAllRoleChangeRequests();
      setState(() {
        _requests = requests;
      });
    } catch (e) {
      Logger.error('Failed to load role change requests: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading requests: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<RoleChangeRequest> get _filteredRequests {
    if (_selectedStatus == 'all') {
      return _requests;
    }
    return _requests.where((request) => request.status == _selectedStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Role Change Requests'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [
          const BothActions(),
        ],
      ),
      drawer: nav.NavigationDrawer(
        currentRoute: AppRoutes.roleChangeManagement,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadRequests,
                    child: _buildRequestsList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statusFilters.map((filter) {
                  final isSelected = _selectedStatus == filter['value'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter['label']!),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatus = filter['value']!;
                        });
                      },
                      selectedColor: const Color(0xFF6366F1).withOpacity(0.2),
                      checkmarkColor: const Color(0xFF6366F1),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    final filteredRequests = _filteredRequests;
    
    if (filteredRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No requests found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredRequests.length,
      itemBuilder: (context, index) {
        final request = filteredRequests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildRequestCard(RoleChangeRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getStatusColor(request.status),
                  child: Icon(
                    request.requestType == 'become_new_provider'
                        ? Icons.business_center
                        : Icons.person_add,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.requestTypeDisplayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Submitted ${_formatDate(request.createdDate)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(request.status),
              ],
            ),
            if (request.requestMessage != null && request.requestMessage!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Message:',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(request.requestMessage!),
            ],
            if (request.proposedProviderData != null) ...[
              const SizedBox(height: 12),
              Text(
                'Provider Details:',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text('Name: ${request.proposedProviderData!['provider_name'] ?? 'N/A'}'),
              Text('Country: ${request.proposedProviderData!['country'] ?? 'N/A'}'),
              Text('Email: ${request.proposedProviderData!['email_address'] ?? 'N/A'}'),
            ],
            if (request.adminNotes != null && request.adminNotes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Notes:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(request.adminNotes!),
                  ],
                ),
              ),
            ],
            if (request.isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _processRequest(request, 'approved'),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _processRequest(request, 'rejected'),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'approved':
        color = Colors.green;
        label = 'Approved';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejected';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _processRequest(RoleChangeRequest request, String status) async {
    final adminNotes = await _showAdminNotesDialog(status);
    if (adminNotes == null) return;

    try {
      Logger.info('🔄 Processing request: ${request.id} with status: $status');
      Logger.info('📝 Admin notes: $adminNotes');
      Logger.info('📋 Request type: ${request.requestType}');
      
      await _roleChangeService.processRoleChangeRequest(
        request.id,
        status,
        adminNotes,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request $status successfully'),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
          ),
        );
        _loadRequests();
      }
    } catch (e) {
      Logger.error('❌ Failed to process request: $e');
      
      // Show more detailed error message
      String errorMessage = 'Error processing request';
      if (e.toString().contains('Admin notes are required')) {
        errorMessage = 'Admin notes are required to process this request.';
      } else if (e.toString().contains('Validation Error')) {
        // Extract the validation error details
        final errorStr = e.toString();
        final startIndex = errorStr.indexOf('Validation Error: ');
        if (startIndex != -1) {
          errorMessage = errorStr.substring(startIndex + 18);
        } else {
          errorMessage = 'Validation failed. Please check your input.';
        }
      } else if (e.toString().contains('Invalid request')) {
        errorMessage = 'Invalid request data. Please try again.';
      } else if (e.toString().contains('400')) {
        errorMessage = 'Bad request. Please check that all required fields are filled.';
      } else if (e.toString().contains('401')) {
        errorMessage = 'Authentication required. Please log in again.';
      } else if (e.toString().contains('403')) {
        errorMessage = 'Access denied. You may not have permission to perform this action.';
      } else if (e.toString().contains('404')) {
        errorMessage = 'Request not found. It may have already been processed.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<String?> _showAdminNotesDialog(String status) async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('${status == 'approved' ? 'Approve' : 'Reject'} Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add notes for this $status decision (required):'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: status == 'approved' 
                      ? 'e.g., Application meets all requirements and is approved.'
                      : 'e.g., Missing required documentation. Please resubmit with complete information.',
                  border: const OutlineInputBorder(),
                  labelText: 'Admin Notes *',
                  helperText: 'Required field - explain your decision',
                ),
                onChanged: (value) => setState(() {}),
              ),
              if (controller.text.trim().isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Admin notes are required to process this request',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () {
                      final notes = controller.text.trim();
                      if (notes.isNotEmpty) {
                        Navigator.of(context).pop(notes);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: status == 'approved' ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(status == 'approved' ? 'Approve' : 'Reject'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}