import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../config/routes.dart';
import '../../models/tour.dart';
import '../../services/dashboard_data_service.dart';
import '../../utils/logger.dart';
import '../../widgets/common/navigation_drawer.dart' as nav;
import '../../widgets/common/notification_icon.dart';
import '../../widgets/common/settings_dropdown.dart';
import '../../widgets/common/safe_bottom_padding.dart';

class TouristDashboardScreen extends StatefulWidget {
  const TouristDashboardScreen({super.key});

  @override
  State<TouristDashboardScreen> createState() => _TouristDashboardScreenState();
}

class _TouristDashboardScreenState extends State<TouristDashboardScreen> {
  Map<String, dynamic> _touristStats = {};
  List<Tour> _upcomingTours = [];
  List<Tour> _recommendedTours = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTouristData();
  }

  Future<void> _loadTouristData() async {
    setState(() => _isLoading = true);

    try {
      final dashboardService = DashboardDataService();
      final dashboardData = await dashboardService.loadTouristDashboard();

      // Extract data from the response
      _touristStats = dashboardData['stats'] as Map<String, dynamic>;
      _upcomingTours = dashboardData['myTours'] as List<Tour>;
      _recommendedTours = dashboardData['recommendedTours'] as List<Tour>;

      Logger.info('✅ Dashboard data loaded successfully');
    } catch (e) {
      Logger.error('❌ Error loading tourist data: $e');
      // Set empty data on error
      _touristStats = {
        'total_registrations': 0,
        'active_tours': 0,
        'completed_tours': 0,
      };
      _upcomingTours = [];
      _recommendedTours = [];
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tourlicity'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: const [
          NotificationIcon(),
          SettingsDropdown(),
        ],
      ),
      drawer: nav.NavigationDrawer(
        currentRoute: AppRoutes.dashboard,
        onJoinTour: _showJoinTourDialog,
      ),
      body: SafeArea(
        bottom: true,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadTouristData,
                child: SafeScrollView(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                  ),
                  minBottomPadding: 80, // Extra padding for floating action button
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Section
                      Card(
                        color: const Color.fromRGBO(99, 102, 241, 0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: const Color(0xFF6366F1),
                                backgroundImage: user?.profilePicture != null
                                    ? NetworkImage(user!.profilePicture!)
                                    : null,
                                child: user?.profilePicture == null
                                    ? Text(
                                        user?.name
                                                ?.substring(0, 1)
                                                .toUpperCase() ??
                                            'T',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome back, ${user?.name?.split(' ').first ?? 'Tourist'}!',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Ready for your next adventure?',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Quick Stats
                      const Text(
                        'Your Journey',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatsGrid(),

                      const SizedBox(height: 32),

                      // Quick Actions
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildQuickActions(),

                      const SizedBox(height: 32),

                      // Upcoming Tours
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Upcoming Tours',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push(AppRoutes.myTours),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildUpcomingTours(),

                      const SizedBox(height: 32),

                      // Recommended Tours
                      const Text(
                        'Recommended for You',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRecommendedTours(),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showJoinTourDialog(),
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Join Tour'),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          'Tours Joined',
          _touristStats['total_registrations']?.toString() ?? '0',
          Icons.tour,
          Colors.blue,
        ),
        _buildStatCard(
          'Active Tours',
          _touristStats['active_tours']?.toString() ?? '0',
          Icons.directions_walk,
          Colors.orange,
        ),
        _buildStatCard(
          'Completed',
          _touristStats['completed_tours']?.toString() ?? '0',
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'Upcoming',
          _upcomingTours.length.toString(),
          Icons.schedule,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            'Search Tours',
            Icons.search,
            Colors.blue,
            () => context.push(AppRoutes.tourSearch),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            'My Tours',
            Icons.tour,
            Colors.green,
            () => context.push(AppRoutes.myTours),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            'Join Tour',
            Icons.qr_code_scanner,
            Colors.orange,
            () => _showJoinTourDialog(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingTours() {
    if (_upcomingTours.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(Icons.event_available, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No upcoming tours',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Join a tour to see it here',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.push(AppRoutes.tourSearch),
                child: const Text('Browse Tours'),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _upcomingTours.length,
        itemBuilder: (context, index) {
          final tour = _upcomingTours[index];
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tour.tourName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Chip(
                          label: const Text('Available'),
                          backgroundColor: const Color.fromRGBO(
                            76,
                            175,
                            80,
                            0.1,
                          ),
                          labelStyle: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tour.description ?? '',
                      style: TextStyle(color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.people, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${tour.currentRegistrations}/${tour.maxTourists}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${tour.durationDays} day${tour.durationDays > 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Code: ${tour.joinCode}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
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

  Widget _buildRecommendedTours() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _recommendedTours.length,
        itemBuilder: (context, index) {
          final tour = _recommendedTours[index];
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16),
            child: Card(
              child: InkWell(
                onTap: () => _showTourDetails(tour),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tour.tourName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Chip(
                            label: const Text('Recommended'),
                            backgroundColor: const Color.fromRGBO(
                              33,
                              150,
                              243,
                              0.1,
                            ),
                            labelStyle: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tour.description ?? '',
                        style: TextStyle(color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.people, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${tour.remainingTourists} spots left',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${tour.durationDays} day${tour.durationDays > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showJoinTourDialog() {
    final TextEditingController codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Tour'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the tour join code:'),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Join Code',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _joinTourWithCode(codeController.text.trim());
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  void _joinTourWithCode(String code) {
    if (code.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a join code')));
      return;
    }

    // Search for tour by join code and navigate to registration
    try {
      // This would call the API to search for the tour
      // For now, show a message that the functionality is being implemented
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(
        content: Text('Tour search functionality will be implemented with backend integration'),
        backgroundColor: Colors.orange,
      ));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
        content: Text('Error searching for tour: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _showTourDetails(Tour tour) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tour.tourName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tour.description ?? ''),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.people, size: 16),
                const SizedBox(width: 4),
                Text('${tour.remainingTourists} spots remaining'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${tour.durationDays} day${tour.durationDays > 1 ? 's' : ''}',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attach_money, size: 16),
                const SizedBox(width: 4),
                const Text('Contact for pricing'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Joining ${tour.tourName}...')),
              );
            },
            child: const Text('Join Tour'),
          ),
        ],
      ),
    );
  }
}
