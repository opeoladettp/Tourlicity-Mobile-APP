import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tour_provider.dart';
import '../../config/routes.dart';
import '../../widgets/common/navigation_drawer.dart' as nav;
import '../../widgets/dashboard/tourist_dashboard_content.dart';
import '../../widgets/dashboard/provider_dashboard_content.dart';
import '../../widgets/dashboard/admin_dashboard_content.dart';
import '../../widgets/common/notification_icon.dart';
import '../../widgets/common/settings_dropdown.dart';

class UnifiedDashboardScreen extends StatefulWidget {
  const UnifiedDashboardScreen({super.key});

  @override
  State<UnifiedDashboardScreen> createState() => _UnifiedDashboardScreenState();
}

class _UnifiedDashboardScreenState extends State<UnifiedDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final tourProvider = Provider.of<TourProvider>(context, listen: false);
      
      // Load data based on user role (user data already loaded by main.dart)
      if (authProvider.user != null) {
        switch (authProvider.user!.userType) {
          case 'tourist':
            tourProvider.loadMyTours();
            break;
          case 'provider_admin':
            tourProvider.loadProviderStats();
            tourProvider.loadProviderTours();
            break;
          case 'system_admin':
            // Load admin-specific data
            break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(_getDashboardTitle(user.userType)),
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            actions: [
              ..._buildAppBarActions(user.userType),
              const NotificationIcon(),
              const SettingsDropdown(),
            ],
          ),
          drawer: nav.NavigationDrawer(
            currentRoute: '/dashboard',
          ),
          body: _buildDashboardContent(user.userType),
        );
      },
    );
  }

  String _getDashboardTitle(String userType) {
    switch (userType) {
      case 'tourist':
        return 'My Tours';
      case 'provider_admin':
        return 'Provider Dashboard';
      case 'system_admin':
        return 'Admin Dashboard';
      default:
        return 'Dashboard';
    }
  }

  List<Widget> _buildAppBarActions(String userType) {
    switch (userType) {
      case 'tourist':
        return [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push(AppRoutes.tourSearch),
            tooltip: 'Search Tours',
          ),
        ];
      case 'provider_admin':
        return [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(AppRoutes.tourManagement),
            tooltip: 'Create Tour',
          ),
        ];
      case 'system_admin':
        return [];
      default:
        return [];
    }
  }

  Widget _buildDashboardContent(String userType) {
    switch (userType) {
      case 'tourist':
        return const TouristDashboardContent();
      case 'provider_admin':
        return const ProviderDashboardContent();
      case 'system_admin':
        return const AdminDashboardContent();
      default:
        return const Center(
          child: Text('Unknown user type'),
        );
    }
  }
}