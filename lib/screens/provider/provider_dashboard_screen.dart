import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/tour_provider.dart';
import '../../config/routes.dart';
import '../../widgets/common/error_message.dart';
import '../../widgets/common/navigation_drawer.dart' as nav;
import '../../widgets/common/notification_icon.dart';
import '../../widgets/common/settings_dropdown.dart';
import '../../widgets/common/safe_bottom_padding.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tourProvider = Provider.of<TourProvider>(context, listen: false);
      tourProvider.loadProviderStats();
      tourProvider.loadProviderTours();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Dashboard'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(AppRoutes.tourManagement),
            tooltip: 'Create Tour',
          ),
          const NotificationIcon(),
          const SettingsDropdown(),
        ],
      ),
      drawer: nav.NavigationDrawer(
        currentRoute: AppRoutes.dashboard,
      ),
      body: Consumer<TourProvider>(
        builder: (context, tourProvider, child) {
          if (tourProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (tourProvider.error != null) {
            return ErrorMessage(
              message: tourProvider.error!,
              onRetry: () {
                tourProvider.loadProviderStats();
                tourProvider.loadProviderTours();
              },
            );
          }

          return SafeArea(
            bottom: true,
            child: RefreshIndicator(
              onRefresh: () async {
                await tourProvider.loadProviderStats();
                await tourProvider.loadProviderTours();
              },
              child: SafeScrollView(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                ),
                minBottomPadding: 32,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Cards
                    if (tourProvider.providerStats != null) ...[
                      const Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatsGrid(tourProvider.providerStats!),
                      const SizedBox(height: 32),
                    ],
                    
                    // Tours Section
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
                        ElevatedButton.icon(
                          onPressed: () => context.push(AppRoutes.tourManagement),
                          icon: const Icon(Icons.add),
                          label: const Text('New Tour'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                          ),
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
                              'No tours created yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Create your first tour to get started',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => context.push(AppRoutes.tourManagement),
                              icon: const Icon(Icons.add),
                              label: const Text('Create Tour'),
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
                                      const SizedBox(width: 16),
                                      const Icon(Icons.qr_code, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        tour.joinCode,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () => context.push('${AppRoutes.tourManagement}?id=${tour.id}'),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3, // Reduced from 1.5 to give more height
      children: [
        _buildStatCard(
          'Active Tours',
          stats['active_tours']?.toString() ?? '0',
          Icons.tour,
          Colors.blue,
        ),
        _buildStatCard(
          'Total Tourists',
          stats['total_tourists']?.toString() ?? '0',
          Icons.people,
          Colors.green,
        ),
        _buildStatCard(
          'Pending Registrations',
          stats['pending_registrations']?.toString() ?? '0',
          Icons.pending,
          Colors.orange,
        ),
        _buildStatCard(
          'Completed Tours',
          stats['completed_tours']?.toString() ?? '0',
          Icons.done_all,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
}