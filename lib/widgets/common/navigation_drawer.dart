import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../config/routes.dart';
import 'safe_bottom_padding.dart';

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
              user?.fullName.isNotEmpty == true ? user!.fullName : 'Tourist',
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
                      user?.fullName.isNotEmpty == true ? user!.fullName.substring(0, 1).toUpperCase() : 'T',
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
                  title: 'Dashboard',
                  route: AppRoutes.dashboard,
                  color: Colors.blue,
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
                _buildDrawerItem(
                  context,
                  icon: Icons.campaign,
                  title: 'Tour Messages',
                  route: AppRoutes.tourBroadcasts,
                  color: Colors.indigo,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.event_note,
                  title: 'My Itinerary',
                  route: AppRoutes.tourItineraryView,
                  color: Colors.teal,
                ),
                // Tour Templates - Only for Admins and Providers
                if (user?.userType != 'tourist')
                  _buildDrawerItem(
                    context,
                    icon: Icons.description_outlined,
                    title: 'Browse Templates',
                    route: AppRoutes.tourTemplateBrowse,
                    color: Colors.purple,
                  ),
                _buildDrawerItem(
                  context,
                  icon: Icons.qr_code_scanner,
                  title: 'Scan QR Code',
                  route: AppRoutes.qrScanner,
                  color: Colors.orange,
                ),
                if (onJoinTour != null)
                  _buildDrawerAction(
                    context,
                    icon: Icons.input,
                    title: 'Enter Join Code',
                    onTap: onJoinTour!,
                    color: Colors.orange,
                  ),
                
                const Divider(),
                
                // Provider Section
                if (user?.userType == 'tourist') ...[
                  _buildSectionHeader('Provider Services'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.business,
                    title: 'Become a Provider',
                    route: AppRoutes.providerRegistration,
                    color: const Color(0xFF6366F1),
                  ),
                ],
                if (user?.userType == 'provider_admin') ...[
                  _buildSectionHeader('Provider Services'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.tour,
                    title: 'Tour Management',
                    route: AppRoutes.tourManagement,
                    color: Colors.indigo,
                  ),
                ],
                
                const Divider(),
                
                // System Admin Section
                if (user?.userType == 'system_admin') ...[
                  _buildSectionHeader('System Admin'),
                  _buildDrawerItem(
                    context,
                    icon: Icons.pending_actions,
                    title: 'Role Change Requests',
                    route: AppRoutes.roleChangeManagement,
                    color: Colors.orange,
                  ),
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
                  _buildDrawerItem(
                    context,
                    icon: Icons.description_outlined,
                    title: 'Tour Templates',
                    route: AppRoutes.tourTemplateManagement,
                    color: Colors.indigo,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.event_note,
                    title: 'Tour Itineraries',
                    route: AppRoutes.tourItineraryManagement,
                    color: Colors.teal,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.library_books,
                    title: 'Activity Templates',
                    route: AppRoutes.defaultActivityManagement,
                    color: Colors.deepPurple,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.campaign,
                    title: 'Tour Broadcasts',
                    route: AppRoutes.tourBroadcastManagement,
                    color: Colors.indigo,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.notifications_active,
                    title: 'Create Notification',
                    route: AppRoutes.notificationManagement,
                    color: Colors.red,
                  ),
                  const Divider(),
                ],
              ],
            ),
          ),
          
          // Footer with safe bottom padding
          SafeBottomPadding(
            minPadding: 0,
            child: Column(
              children: [
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
          ),
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


}