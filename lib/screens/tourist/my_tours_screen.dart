import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tour_provider.dart';
import '../../config/routes.dart';
import '../../widgets/common/error_message.dart';
import '../../utils/logger.dart';

class MyToursScreen extends StatefulWidget {
  const MyToursScreen({super.key});

  @override
  State<MyToursScreen> createState() => _MyToursScreenState();
}

class _MyToursScreenState extends State<MyToursScreen> {
  @override
  void initState() {
    super.initState();
    // Don't automatically load tours to avoid timeout in offline mode
    // User can manually refresh if backend is available
    Logger.debug('📱 My Tours screen loaded - use pull-to-refresh to load tours');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tours'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push(AppRoutes.tourSearch),
          ),
          PopupMenuButton(
            onSelected: (value) {
              if (value == 'logout') {
                _signOut(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer2<TourProvider, AuthProvider>(
        builder: (context, tourProvider, authProvider, child) {
          if (tourProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (tourProvider.error != null) {
            return ErrorMessage(
              message: tourProvider.error!,
              onRetry: () => tourProvider.loadMyTours(),
            );
          }

          if (tourProvider.tours.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.tour_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No tours found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),     
             const SizedBox(height: 8),
                  const Text(
                    'Join a tour using a join code',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.push(AppRoutes.tourSearch),
                    icon: const Icon(Icons.search),
                    label: const Text('Search Tours'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              Logger.debug('🔄 Manual refresh triggered');
              await tourProvider.loadMyTours();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tourProvider.tours.length,
              itemBuilder: (context, index) {
                final tour = tourProvider.tours[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF6366F1),
                      child: Text(
                        tour.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      tour.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (tour.description != null)
                          Text(tour.description!),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              _getStatusIcon(tour.status),
                              size: 16,
                              color: _getStatusColor(tour.status),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tour.status.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(tour.status),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      onSelected: (value) {
                        if (value == 'unregister') {
                          _showUnregisterDialog(context, tour.id, tour.name);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'unregister',
                          child: Row(
                            children: [
                              Icon(Icons.exit_to_app, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Unregister'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return Icons.check_circle;
      case 'draft':
        return Icons.edit;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return Colors.green;
      case 'draft':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showUnregisterDialog(BuildContext context, String tourId, String tourName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unregister from Tour'),
        content: Text('Are you sure you want to unregister from "$tourName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<TourProvider>(context, listen: false)
                  .unregisterFromTour(tourId);
            },
            child: const Text('Unregister', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _signOut(BuildContext context) {
    Provider.of<AuthProvider>(context, listen: false).signOut();
  }
}