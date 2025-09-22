import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/logger.dart';

class DebugLoginScreen extends StatelessWidget {
  const DebugLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Login'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Debug Login Screen',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 32),

                // Status indicators
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('Loading: ${authProvider.isLoading}'),
                        Text('User: ${authProvider.user?.email ?? 'None'}'),
                        Text('Error: ${authProvider.error ?? 'None'}'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Simple test button
                ElevatedButton(
                  onPressed: () {
                    Logger.debug('🔘 Simple button pressed!');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Button works!')),
                    );
                  },
                  child: const Text('Test Button'),
                ),

                const SizedBox(height: 16),

                // Google Sign In Button
                ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () {
                          Logger.debug('🔘 Google sign-in button pressed!');
                          _signInWithGoogle(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: authProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Google Sign In'),
                ),

                const SizedBox(height: 16),

                // Manual navigation test
                ElevatedButton(
                  onPressed: () {
                    Logger.debug('🔘 Manual navigation button pressed!');
                    Navigator.of(context).pushReplacementNamed('/my-tours');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Manual Navigate to My Tours'),
                ),

                if (authProvider.error != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Error: ${authProvider.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _signInWithGoogle(BuildContext context) {
    Logger.debug('🔐 Starting Google Sign-In from debug screen...');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.signInWithGoogle();
  }
}
