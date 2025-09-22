import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../config/routes.dart';

class NavigationDrawer extends StatelessWidget {
  final String currentRoute;
  final VoidCallback? onJoinTour;

  const NavigationDrawer({
    super.key,
    required this.currentRoute,
    this.onJoinTour,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Drawer(
      child: Column(
        children: [
          // Header
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF6366F1),
            ),
            accountName: Text(
              user?.name ?? 'Tourist',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(user?.email ?? 'No email'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: user?.profilePicture != null 
                  ? NetworkImage(user!.profilePicture!) 
                  : null,
              child: user?.profilePicture == null 
                  ? Text(
                      user?.name?.substring(0, 1).toUpperCase() ?? 'T',
                      style: const TextStyle(
                        color: Color(0xFF6366F1),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          
          // Navigation Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Dashboard Section
                _buildSectionHeader('Dashboard'),
                _buildDrawerItem(
                  context,
                  icon: Icons.dashboard,
                  title: 'Tourist Dashboard',
                  route: AppRoutes.touristDashboard,
                  color: Colors.blue,
                ),
                if (user?.userType == 'provider_admin' || user?.userType == 'system_admin')
                  _buildDrawerItem(
                    context,
                    icon: Icons.business_center,
                    title: 'Provider Dashboard',
                    route: AppRoutes.providerDashboard,
                    color: Colors.green,
                  ),
                if (user?.userType == 'system_admin')
                  _buildDrawerItem(
                    context,
                    icon: Icons.admin_panel_settings,
                    title: 'System Dashboard',
                    route: AppRoutes.systemDashboard,
                    color: Colors.purple,
                  ),
                
                const Divider(),
                
                // Tours Section
                _buildSectionHeader('Tours'),
                _buildDrawerItem(
                  context,
                  icon: Icons.search,
                  title: 'Search Tours',
                  route: AppRoutes.tourSearch,
                  color: Colors.blue,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.list,
                  title: 'My Tours',
                  route: AppRoutes.myTours,
                  color: Colors.green,
                ),
                if (onJoinTour != null)
                  _buildDrawerAction(
                    context,
                    icon: Icons.qr_code_scanner,
                    title: 'Join Tour',
                    onTap: onJoinTour!,
                    color: Colors.orange,
                  ),
                
                const Divider(),
                
                // Provider Section
                _buildSectionHeader('Provider Services'),
                _buildDrawerItem(
                  context,
                  icon: Icons.business,
                  title: 'Become a Provider',
                  route: AppRoutes.providerRegistration,
                  color: const Color(0xFF6366F1),
                ),
                if (user?.userType == 'provider_admin')
                  _buildDrawerItem(
                    context,
                    icon: Icons.tour,
                    title: 'Tour Management',
                    route: AppRoutes.tourManagement,
                    color: Colors.indigo,
                  ),
                
                const Divider(),
                
                // System Admin Section
                if (user?.userType == 'system_admin') ...[
                  _buildSectionHeader('System Admin'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.people,
                    title: 'User Management',
                    route: AppRoutes.userManagement,
                    color: Colors.blue,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.business,
                    title: 'Provider Management',
                    route: AppRoutes.providerManagement,
                    color: Colors.green,
                  ),
                  const Divider(),
                ],
                
                // Account Section
                _buildSectionHeader('Account'),
                _buildDrawerAction(
                  context,
                  icon: Icons.person,
                  title: 'Profile',
                  onTap: () => _showProfileDialog(context),
                  color: Colors.blue,
                ),
              ],
            ),
          ),
          
          // Footer
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.of(context).pop();
              authProvider.signOut();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    required Color color,
  }) {
    final isSelected = currentRoute == route;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? color : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? color : Colors.grey[800],
        ),
      ),
      selected: isSelected,
      selectedTileColor: color.withValues(alpha: 0.1),
      onTap: () {
        Navigator.of(context).pop();
        if (!isSelected) {
          context.push(route);
        }
      },
    );
  }

  Widget _buildDrawerAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
    );
  }

  void _showProfileDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF6366F1),
              backgroundImage: user?.profilePicture != null 
                  ? NetworkImage(user!.profilePicture!) 
                  : null,
              child: user?.profilePicture == null 
                  ? Text(
                      user?.name?.substring(0, 1).toUpperCase() ?? 'T',
                      style: const TextStyle(color: Colors.white, fontSize: 32),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              user?.name ?? 'Tourist',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? 'No email',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(
                (user?.userType ?? 'tourist').replaceAll('_', ' ').toUpperCase(),
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
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
}