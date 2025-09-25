import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/tour_provider.dart';
import 'providers/notification_provider.dart';
import 'config/routes.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TourlicityApp());
}

class TourlicityApp extends StatelessWidget {
  const TourlicityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TourProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Only initialize once when the app starts - prevent infinite loop
          if (!authProvider.hasCheckedAuth) {
            // Capture the notification provider reference before async operations
            final notificationProvider = Provider.of<NotificationProvider>(
              context,
              listen: false,
            );
            
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              // Start auth check first
              await authProvider.checkAuthStatus();

              // Wait a bit before initializing notifications to prevent rate limiting
              await Future.delayed(const Duration(seconds: 1));

              // Initialize notifications in background (non-blocking)
              // Using the captured provider reference instead of context
              notificationProvider.initialize().catchError((e) {
                // Silently handle initialization errors
                Logger.error('Notification initialization failed: $e');
              });
            });
          }

          return MaterialApp.router(
            title: 'Tourlicity',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6366F1),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
              cardTheme: const CardThemeData(elevation: 2),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            routerConfig: AppRoutes.createRouter(),
          );
        },
      ),
    );
  }
}
