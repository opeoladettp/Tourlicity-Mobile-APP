import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/tour_provider.dart';
import 'providers/notification_provider.dart';
import 'config/routes.dart';

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
          // Check auth status and initialize notifications on app startup
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            // Start auth check (non-blocking)
            authProvider.checkAuthStatus();

            // Initialize notifications in background (non-blocking)
            final notificationProvider = Provider.of<NotificationProvider>(
              context,
              listen: false,
            );
            // Don't await - let it initialize in background
            notificationProvider.initialize().catchError((e) {
              // Silently handle initialization errors
              print('Notification initialization failed: $e');
            });
          });

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
