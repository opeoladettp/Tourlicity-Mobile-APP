import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/profile_completion_screen.dart';

class RouteGuard {
  static Widget guard({
    required Widget child,
    bool requireAuth = true,
    bool requireCompleteProfile = true,
  }) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Check if authentication is required and user is not authenticated
        if (requireAuth && !authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        // Check if profile completion is required
        if (requireAuth && 
            requireCompleteProfile && 
            authProvider.isAuthenticated && 
            authProvider.requiresProfileCompletion) {
          return const ProfileCompletionScreen();
        }

        // Check if user can access main app
        if (requireAuth && 
            requireCompleteProfile && 
            authProvider.isAuthenticated && 
            !authProvider.canAccessMainApp) {
          return const ProfileCompletionScreen();
        }

        // All checks passed, show the requested widget
        return child;
      },
    );
  }

  static bool canAccessRoute(BuildContext context, {
    bool requireAuth = true,
    bool requireCompleteProfile = true,
  }) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (requireAuth && !authProvider.isAuthenticated) {
      return false;
    }

    if (requireAuth && 
        requireCompleteProfile && 
        authProvider.requiresProfileCompletion) {
      return false;
    }

    if (requireAuth && 
        requireCompleteProfile && 
        !authProvider.canAccessMainApp) {
      return false;
    }

    return true;
  }

  static void navigateWithGuard(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool requireAuth = true,
    bool requireCompleteProfile = true,
  }) {
    if (canAccessRoute(
      context,
      requireAuth: requireAuth,
      requireCompleteProfile: requireCompleteProfile,
    )) {
      Navigator.pushNamed(context, routeName, arguments: arguments);
    } else {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (!authProvider.isAuthenticated) {
        Navigator.pushReplacementNamed(context, '/login');
      } else if (authProvider.requiresProfileCompletion) {
        Navigator.pushReplacementNamed(context, '/profile-completion');
      }
    }
  }

  static void replaceWithGuard(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool requireAuth = true,
    bool requireCompleteProfile = true,
  }) {
    if (canAccessRoute(
      context,
      requireAuth: requireAuth,
      requireCompleteProfile: requireCompleteProfile,
    )) {
      Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
    } else {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (!authProvider.isAuthenticated) {
        Navigator.pushReplacementNamed(context, '/login');
      } else if (authProvider.requiresProfileCompletion) {
        Navigator.pushReplacementNamed(context, '/profile-completion');
      }
    }
  }
}