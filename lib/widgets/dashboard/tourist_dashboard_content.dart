import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/tour_provider.dart';
import '../../config/routes.dart';
import '../common/error_message.dart';

class TouristDashboardContent extends StatelessWidget {
  const TouristDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TourProvider>(
      builder: (context, tourProvider, child) {
        if (tourProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (tourProvider.error != null) {
          return ErrorMessage(
            message: tourProvider.error!,
            onRetry: () {
              tourProvider.loadMyTours();
            },
          );
        }

        return SafeArea(
          bottom: true,
          child: RefreshIndicator(
            onRefresh: () async {
              await tourProvider.loadMyTours();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome to Tourlicity!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Discover amazing tours and experiences',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => context.push(AppRoutes.tourSearch),
                                  icon: const Icon(Icons.search),
                                  label: const Text('Search Tours'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366F1),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => context.push(AppRoutes.tourTemplateBrowse),
                                  icon: const Icon(Icons.description_outlined),
                                  label: const Text('Browse Templates'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // My Tours Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Tours',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => context.push(AppRoutes.myTours),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (tourProvider.tours.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 32),
                          const Icon(
                            Icons.tour_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No tours booked yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Start exploring and book your first tour',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context.push(AppRoutes.tourSearch),
                            icon: const Icon(Icons.search),
                            label: const Text('Browse Tours'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tourProvider.tours.length > 3 ? 3 : tourProvider.tours.length,
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
                                  Text(
                                    tour.description!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              // Navigate to tour details
                            },
                          ),
                        );
                      },
                    ),
                  
                  if (tourProvider.tours.length > 3) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => context.push(AppRoutes.myTours),
                        child: Text('View all ${tourProvider.tours.length} tours'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
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
}