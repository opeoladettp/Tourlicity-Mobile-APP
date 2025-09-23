import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/profile_completion_screen.dart';
import '../screens/tourist/tourist_dashboard_screen.dart';
import '../screens/tourist/my_tours_screen.dart';
import '../screens/tourist/tour_search_screen.dart';
import '../screens/provider/provider_dashboard_screen.dart';
import '../screens/provider/tour_management_screen.dart';
import '../screens/provider/provider_registration_screen.dart';
import '../screens/system/system_dashboard_screen.dart';
import '../screens/system/user_management_screen.dart';
import '../screens/system/provider_management_screen.dart';
import '../screens/admin/system_admin_dashboard_screen.dart';
import '../screens/admin/role_change_management_screen.dart';
import '../screens/admin/tour_template_management_screen.dart';
import '../screens/admin/custom_tour_management_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String profileCompletion = '/profile-completion';
  static const String touristDashboard = '/tourist-dashboard';
  static const String myTours = '/my-tours';
  static const String tourSearch = '/tour-search';
  static const String providerDashboard = '/provider-dashboard';
  static const String tourManagement = '/tour-management';
  static const String providerRegistration = '/provider-registration';
  static const String systemDashboard = '/system-dashboard';
  static const String userManagement = '/user-management';
  static const String providerManagement = '/provider-management';
  
  // New System Admin routes
  static const String systemAdminDashboard = '/system-admin-dashboard';
  static const String roleChangeManagement = '/role-change-management';
  static const String tourTemplateManagement = '/tour-template-management';
  static const String customTourManagement = '/custom-tour-management';

  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: login,
      redirect: (context, state) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        // Don't call checkAuthStatus here as it causes setState during build
        // Auth status should be checked in main.dart or app initialization
        
        final user = authProvider.user;
        final currentPath = state.matchedLocation;
        
        // If not authenticated, go to login (except if already on login)
        if (user == null) {
          if (currentPath != login) {
            return login;
          }
          return null;
        }
        
        // If profile incomplete, go to profile completion (except if already there)
        if (authProvider.requiresProfileCompletion) {
          if (currentPath != profileCompletion) {
            return profileCompletion;
          }
          return null;
        }
        
        // If authenticated with complete profile but on auth pages, redirect to dashboard
        if (currentPath == login || currentPath == profileCompletion) {
          switch (user.userType) {
            case 'tourist':
              return touristDashboard;
            case 'provider_admin':
              return providerDashboard;
            case 'system_admin':
              return systemAdminDashboard;
            default:
              return touristDashboard;
          }
        }
        
        return null; // No redirect needed
      },
      routes: [
        GoRoute(
          path: login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: profileCompletion,
          builder: (context, state) => const ProfileCompletionScreen(),
        ),
        GoRoute(
          path: touristDashboard,
          builder: (context, state) => const TouristDashboardScreen(),
        ),
        GoRoute(
          path: myTours,
          builder: (context, state) => const MyToursScreen(),
        ),
        GoRoute(
          path: tourSearch,
          builder: (context, state) => const TourSearchScreen(),
        ),
        GoRoute(
          path: providerDashboard,
          builder: (context, state) => const ProviderDashboardScreen(),
        ),
        GoRoute(
          path: tourManagement,
          builder: (context, state) => const TourManagementScreen(),
        ),
        GoRoute(
          path: providerRegistration,
          builder: (context, state) => const ProviderRegistrationScreen(),
        ),
        GoRoute(
          path: systemDashboard,
          builder: (context, state) => const SystemDashboardScreen(),
        ),
        GoRoute(
          path: userManagement,
          builder: (context, state) => const UserManagementScreen(),
        ),
        GoRoute(
          path: providerManagement,
          builder: (context, state) => const ProviderManagementScreen(),
        ),
        // New System Admin routes
        GoRoute(
          path: systemAdminDashboard,
          builder: (context, state) => const SystemAdminDashboardScreen(),
        ),
        GoRoute(
          path: roleChangeManagement,
          builder: (context, state) => const RoleChangeManagementScreen(),
        ),
        GoRoute(
          path: tourTemplateManagement,
          builder: (context, state) => const TourTemplateManagementScreen(),
        ),
        GoRoute(
          path: customTourManagement,
          builder: (context, state) => const CustomTourManagementScreen(),
        ),
      ],
    );
  }
}