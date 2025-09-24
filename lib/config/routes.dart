import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/profile_completion_screen.dart';
import '../screens/auth/profile_update_screen.dart';
import '../screens/dashboard/unified_dashboard_screen.dart';
import '../screens/tourist/my_tours_screen.dart';
import '../screens/tourist/tour_search_screen.dart';
import '../screens/provider/tour_management_screen.dart';
import '../screens/provider/provider_registration_screen.dart';
import '../screens/system/user_management_screen.dart';
import '../screens/system/provider_management_screen.dart';
import '../screens/admin/role_change_management_screen.dart';
import '../screens/admin/tour_template_management_screen.dart';
import '../screens/admin/tour_template_activities_screen.dart';
import '../screens/admin/broadcast_notification_screen.dart';
import '../screens/admin/notification_management_screen.dart';
import '../screens/admin/custom_tour_management_screen.dart';
import '../screens/common/qr_scanner_screen.dart';
import '../screens/common/notifications_screen.dart';
import '../screens/tourist/tour_template_browse_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String profileCompletion = '/profile-completion';
  static const String profileUpdate = '/profile-update';
  static const String dashboard = '/dashboard';
  static const String myTours = '/my-tours';
  static const String tourSearch = '/tour-search';
  static const String tourManagement = '/tour-management';
  static const String providerRegistration = '/provider-registration';
  static const String userManagement = '/user-management';
  static const String providerManagement = '/provider-management';
  static const String roleChangeManagement = '/role-change-management';
  static const String tourTemplateManagement = '/tour-template-management';
  static const String tourTemplateActivities = '/tour-template-activities';
  static const String broadcastNotification = '/broadcast-notification';
  static const String notificationManagement = '/notification-management';
  static const String customTourManagement = '/custom-tour-management';
  static const String qrScanner = '/qr-scanner';
  static const String notifications = '/notifications';
  static const String tourTemplateBrowse = '/tour-template-browse';

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
          return dashboard;
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
          path: profileUpdate,
          builder: (context, state) => const ProfileUpdateScreen(),
        ),
        GoRoute(
          path: dashboard,
          builder: (context, state) => const UnifiedDashboardScreen(),
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
          path: tourManagement,
          builder: (context, state) => const TourManagementScreen(),
        ),
        GoRoute(
          path: providerRegistration,
          builder: (context, state) => const ProviderRegistrationScreen(),
        ),
        GoRoute(
          path: userManagement,
          builder: (context, state) => const UserManagementScreen(),
        ),
        GoRoute(
          path: providerManagement,
          builder: (context, state) => const ProviderManagementScreen(),
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
          path: '$tourTemplateActivities/:templateId',
          builder: (context, state) => TourTemplateActivitiesScreen(
            templateId: state.pathParameters['templateId']!,
          ),
        ),
        GoRoute(
          path: broadcastNotification,
          builder: (context, state) => const BroadcastNotificationScreen(),
        ),
        GoRoute(
          path: notificationManagement,
          builder: (context, state) => const NotificationManagementScreen(),
        ),
        GoRoute(
          path: customTourManagement,
          builder: (context, state) => const CustomTourManagementScreen(),
        ),
        GoRoute(
          path: qrScanner,
          builder: (context, state) => const QRScannerScreen(),
        ),
        GoRoute(
          path: notifications,
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: tourTemplateBrowse,
          builder: (context, state) => const TourTemplateBrowseScreen(),
        ),
      ],
    );
  }
}