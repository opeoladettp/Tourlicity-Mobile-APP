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

  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: login,
      redirect: (context, state) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.user;
        
        // If not authenticated, go to login
        if (user == null) {
          return login;
        }
        
        // If profile incomplete, go to profile completion
        if (!user.isProfileComplete && state.matchedLocation != profileCompletion) {
          return profileCompletion;
        }
        
        // If on login page but authenticated, redirect based on user type
        if (state.matchedLocation == login) {
          switch (user.userType) {
            case 'tourist':
              return touristDashboard;
            case 'provider_admin':
              return providerDashboard;
            case 'system_admin':
              return systemDashboard;
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
      ],
    );
  }
}