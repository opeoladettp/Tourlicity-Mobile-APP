import 'package:flutter/material.dart';
import '../../services/broadcast_service.dart';
import '../../services/tour_service.dart';
import '../../utils/logger.dart';
import '../../widgets/common/navigation_drawer.dart' as nav;
import '../../widgets/common/app_bar_actions.dart';
import '../../widgets/common/safe_bottom_padding.dart';
import '../../models/broadcast.dart';
import '../../models/registration.dart';


class TourBroadcastsScreen extends StatefulWidget {
  const TourBroadcastsScreen({super.key});

  @override
  State<TourBroadcastsScreen> createState() => _TourBroadcastsScreenState();
}

class _TourBroadcastsScreenState extends State<TourBroadcastsScreen> {
  final BroadcastService _broadcastService = BroadcastService();
  final TourService _tourService = TourService();

  List<Registration> _registrations = [];
  Map<String, List<Broadcast>> _tourBroadcasts = {};
  bool _isLoading = false;
  String? _selectedTourId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _loadRegistrations();
      await _loadBroadcasts();
    } catch (e) {
      Logger.error('Failed to load data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRegistrations() async {
    try {
      final registrations = await _tourService.getMyRegistrations();
      setState(() {
        _registrations = registrations
            .where((r) => r.status == 'approved')
            .toList();
        if (_registrations.isNotEmpty && _selectedTourId == null) {
          _selectedTourId =
              _registrations.first.customTour?.id ??
              _registrations.first.customTourId;
        }
      });
    } catch (e) {
      Logger.error('Failed to load registrations: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading your tours: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadBroadcasts() async {
    try {
      final Map<String, List<Broadcast>> broadcasts = {};

      for (final registration in _registrations) {
        try {
          final tourId =
              registration.customTour?.id ?? registration.customTourId;
          final tourBroadcasts = await _broadcastService.getBroadcastsForTour(
            tourId,
            limit: 20,
          );
          broadcasts[tourId] = tourBroadcasts;
        } catch (e) {
          final tourId =
              registration.customTour?.id ?? registration.customTourId;
          Logger.debug('Failed to load broadcasts for tour $tourId: $e');
          broadcasts[tourId] = [];
        }
      }

      setState(() {
        _tourBroadcasts = broadcasts;
      });
    } catch (e) {
      Logger.error('Failed to load broadcasts: $e');
    }
  }

  List<Broadcast> get _currentTourBroadcasts {
    if (_selectedTourId == null) return [];
    return _tourBroadcasts[_selectedTourId] ?? [];
  }

  Registration? get _currentTour {
    if (_selectedTourId == null) return null;
    try {
      return _registrations.firstWhere(
        (r) => (r.customTour?.id ?? r.customTourId) == _selectedTourId,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tour Messages'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [const BothActions()],
      ),
      drawer: nav.NavigationDrawer(currentRoute: '/tour-broadcasts'),
      body: SafeScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_registrations.isNotEmpty) ...[
              _buildTourSelector(),
              const SizedBox(height: 24),
              _buildBroadcastsList(),
            ] else
              _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildTourSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Tour',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedTourId,
              decoration: const InputDecoration(
                labelText: 'Your Tours',
                border: OutlineInputBorder(),
              ),
              items: _registrations.map((registration) {
                final tour = registration.customTour;
                final tourId = tour?.id ?? registration.customTourId;
                final tourName = tour?.tourName ?? 'Unknown Tour';
                final providerName = tour?.provider?.name ?? 'Unknown Provider';
                final broadcastCount = _tourBroadcasts[tourId]?.length ?? 0;

                return DropdownMenuItem(
                  value: tourId,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(tourName),
                      Text(
                        '$providerName • $broadcastCount messages',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTourId = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBroadcastsList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final broadcasts = _currentTourBroadcasts;
    final currentTour = _currentTour;

    if (broadcasts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.campaign, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No messages yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              currentTour != null
                  ? 'Your tour provider hasn\'t sent any messages for "${currentTour.customTour?.tourName ?? 'this tour'}" yet.'
                  : 'No messages available for the selected tour.',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Messages (${broadcasts.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: _loadBroadcasts,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh messages',
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: broadcasts.length,
          itemBuilder: (context, index) {
            final broadcast = broadcasts[index];
            return _buildBroadcastCard(broadcast);
          },
        ),
      ],
    );
  }

  Widget _buildBroadcastCard(Broadcast broadcast) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(
                    0xFF6366F1,
                  ).withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.campaign,
                    color: Color(0xFF6366F1),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        broadcast.provider.providerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDateTime(broadcast.createdDate),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                broadcast.message,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
            ),
            if (broadcast.data != null && broadcast.data!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildBroadcastMetadata(broadcast.data!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBroadcastMetadata(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final urgencyLevel = data['urgency_level'] as String?;

    if (type == null) return const SizedBox.shrink();

    Color color;
    IconData icon;
    String label;

    switch (type) {
      case 'welcome':
        color = Colors.green;
        icon = Icons.waving_hand;
        label = 'Welcome Message';
        break;
      case 'tour_update':
        color = Colors.blue;
        icon = Icons.update;
        label = 'Tour Update';
        break;
      case 'emergency':
        color = Colors.red;
        icon = Icons.emergency;
        label = 'Emergency';
        break;
      case 'meeting_point_update':
        color = Colors.orange;
        icon = Icons.location_on;
        label = 'Meeting Point Update';
        break;
      case 'itinerary_change':
        color = Colors.purple;
        icon = Icons.schedule;
        label = 'Itinerary Change';
        break;
      case 'reminder':
        color = Colors.teal;
        icon = Icons.alarm;
        label = 'Reminder';
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
        label = 'Information';
    }

    // Adjust color for urgency
    if (urgencyLevel == 'high') {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.tour, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No Tours Yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'You haven\'t registered for any tours yet.\nOnce you join a tour, you\'ll see messages from your tour provider here.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/tour-search');
            },
            icon: const Icon(Icons.search),
            label: const Text('Find Tours'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday at ${_formatTime(dateTime)}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
