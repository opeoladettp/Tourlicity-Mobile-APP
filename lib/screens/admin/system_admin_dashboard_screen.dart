import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/role_change_service.dart';
import '../../services/user_management_service.dart';
import '../../services/provider_service.dart';

import '../../models/role_change_request.dart';

import '../../utils/logger.dart';
import '../../config/routes.dart';
import '../../widgets/common/navigation_drawer.dart' as nav;

class SystemAdminDashboardScreen extends StatefulWidget {
  const SystemAdminDashboardScreen({super.key});

  @override
  State<SystemAdminDashboardScreen> createState() =>
      _SystemAdminDashboardScreenState();
}

class _SystemAdminDashboardScreenState
    extends State<SystemAdminDashboardScreen> {
  final RoleChangeService _roleChangeService = RoleChangeService();
  final UserManagementService _userService = UserManagementService();
  final ProviderService _providerService = ProviderService();

  List<RoleChangeRequest> _pendingRequests = [];
  Map<String, dynamic> _systemStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // Load data in parallel
      final results = await Future.wait([
        _loadPendingRoleChangeRequests(),
        _loadSystemStatistics(),
      ]);

      setState(() {
        _pendingRequests = results[0] as List<RoleChangeRequest>;
        _systemStats = results[1] as Map<String, dynamic>;
      });
    } catch (e) {
      Logger.error('Failed to load dashboard data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<List<RoleChangeRequest>> _loadPendingRoleChangeRequests() async {
    try {
      final allRequests = await _roleChangeService.getAllRoleChangeRequests();
      return allRequests.where((request) => request.isPending).toList();
    } catch (e) {
      Logger.error('Failed to load pending requests: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _loadSystemStatistics() async {
    try {
      final userStats = await _userService.getUserStatistics();
      final providerStats = await _providerService.getRegistrationStats();

      return {'users': userStats, 'providers': providerStats};
    } catch (e) {
      Logger.error('Failed to load system statistics: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Admin Dashboard'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      drawer: nav.NavigationDrawer(
        currentRoute: AppRoutes.systemAdminDashboard,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildSystemStats(),
                    const SizedBox(height: 24),
                    _buildPendingRequests(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard() {
    final authProvider = provider_pkg.Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Card(
      color: const Color.fromRGBO(99, 102, 241, 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.admin_panel_settings,
              size: 48,
              color: Color(0xFF6366F1),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${user?.firstName ?? 'Admin'}!',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'System Administrator Dashboard',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildActionCard(
              'Manage Users',
              Icons.people,
              () => context.push(AppRoutes.userManagement),
            ),
            _buildActionCard(
              'Manage Providers',
              Icons.business,
              () => context.push(AppRoutes.providerManagement),
            ),
            _buildActionCard(
              'Tour Templates',
              Icons.description_outlined,
              () => context.push(AppRoutes.tourTemplateManagement),
            ),
            _buildActionCard(
              'Custom Tours',
              Icons.tour,
              () => context.push(AppRoutes.customTourManagement),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: const Color(0xFF6366F1)),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'System Statistics',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Users',
                _systemStats['users']?['total_users']?.toString() ?? '0',
                Icons.people,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Active Providers',
                _systemStats['providers']?['active_providers']?.toString() ??
                    '0',
                Icons.business,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Pending Requests',
                _pendingRequests.length.toString(),
                Icons.pending_actions,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Total Tours',
                _systemStats['providers']?['total_tours']?.toString() ?? '0',
                Icons.tour,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRequests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Pending Role Change Requests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.push(AppRoutes.roleChangeManagement),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_pendingRequests.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('No pending requests')),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pendingRequests.take(5).length,
            itemBuilder: (context, index) {
              final request = _pendingRequests[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF6366F1),
                    child: Icon(
                      request.requestType == 'become_new_provider'
                          ? Icons.business_center
                          : Icons.person_add,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(request.requestTypeDisplayName),
                  subtitle: Text(
                    'Submitted ${_formatDate(request.createdDate)}',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => context.push(AppRoutes.roleChangeManagement),
                ),
              );
            },
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    }
  }
}
