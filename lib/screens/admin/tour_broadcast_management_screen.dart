import 'package:flutter/material.dart';
import '../../services/broadcast_service.dart';
import '../../services/custom_tour_service.dart';
import '../../utils/logger.dart';
import '../../widgets/common/navigation_drawer.dart' as nav;
import '../../widgets/common/app_bar_actions.dart';
import '../../widgets/common/safe_bottom_padding.dart';
import '../../models/broadcast.dart';
import '../../models/custom_tour.dart';

class TourBroadcastManagementScreen extends StatefulWidget {
  const TourBroadcastManagementScreen({super.key});

  @override
  State<TourBroadcastManagementScreen> createState() =>
      _TourBroadcastManagementScreenState();
}

class _TourBroadcastManagementScreenState
    extends State<TourBroadcastManagementScreen> {
  final BroadcastService _broadcastService = BroadcastService();
  final CustomTourService _tourService = CustomTourService();

  List<Broadcast> _broadcasts = [];
  List<CustomTour> _tours = [];
  bool _isLoading = false;
  String? _selectedTourId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadBroadcasts(),
        _loadTours(),
      ]);
    } catch (e) {
      Logger.error('Failed to load data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBroadcasts() async {
    try {
      final broadcasts = await _broadcastService.getAllBroadcasts();
      setState(() {
        _broadcasts = broadcasts;
      });
    } catch (e) {
      Logger.error('Failed to load broadcasts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading broadcasts: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadTours() async {
    try {
      final tours = await _tourService.getAllCustomTours();
      setState(() {
        _tours = tours;
      });
    } catch (e) {
      Logger.error('Failed to load tours: $e');
    }
  }

  List<Broadcast> get _filteredBroadcasts {
    var filtered = _broadcasts;

    if (_selectedTourId != null) {
      filtered = filtered.where((b) => b.customTour.id == _selectedTourId).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((b) =>
          b.message.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.customTour.tourName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.provider.providerName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tour Broadcasts'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [
          const BothActions(),
        ],
      ),
      drawer: nav.NavigationDrawer(
        currentRoute: '/tour-broadcast-management',
      ),
      body: SafeScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilters(),
            const SizedBox(height: 24),
            _buildBroadcastsList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/broadcast-notification');
        },
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.campaign),
        label: const Text('New Broadcast'),
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filters',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search broadcasts',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by message, tour, or provider',
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _selectedTourId,
              decoration: const InputDecoration(
                labelText: 'Filter by Tour',
                border: OutlineInputBorder(),
              ),
              hint: const Text('All tours'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All tours'),
                ),
                ..._tours.map((tour) {
                  return DropdownMenuItem<String?>(
                    value: tour.id,
                    child: Text(tour.tourName),
                  );
                }),
              ],
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

    final filteredBroadcasts = _filteredBroadcasts;

    if (filteredBroadcasts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.campaign, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _broadcasts.isEmpty ? 'No broadcasts yet' : 'No broadcasts match your filters',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              _broadcasts.isEmpty 
                  ? 'Create your first broadcast to communicate with tour participants'
                  : 'Try adjusting your search or filters',
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
        Text(
          'Broadcasts (${filteredBroadcasts.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredBroadcasts.length,
          itemBuilder: (context, index) {
            final broadcast = filteredBroadcasts[index];
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        broadcast.customTour.tourName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'by ${broadcast.provider.providerName}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(broadcast.status),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                broadcast.messagePreview,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  broadcast.createdBy.fullName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(broadcast.createdDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (broadcast.isDraft)
                  TextButton.icon(
                    onPressed: () => _publishBroadcast(broadcast),
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('Publish'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                  ),
                TextButton.icon(
                  onPressed: () => _viewBroadcast(broadcast),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _deleteBroadcast(broadcast),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'published':
        color = Colors.green;
        label = 'Published';
        break;
      case 'draft':
        color = Colors.orange;
        label = 'Draft';
        break;
      default:
        color = Colors.grey;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _publishBroadcast(Broadcast broadcast) async {
    try {
      await _broadcastService.publishBroadcast(broadcast.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Broadcast published successfully! Notifications sent to participants.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      await _loadBroadcasts();
    } catch (e) {
      Logger.error('Failed to publish broadcast: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error publishing broadcast: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewBroadcast(Broadcast broadcast) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(broadcast.customTour.tourName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Provider: ${broadcast.provider.providerName}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                'Status: ${broadcast.statusDisplayName}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                'Created by: ${broadcast.createdBy.fullName}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                'Created: ${_formatDateTime(broadcast.createdDate)}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              const Text(
                'Message:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(broadcast.message),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBroadcast(Broadcast broadcast) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Broadcast'),
        content: Text(
          'Are you sure you want to delete this broadcast for "${broadcast.customTour.tourName}"?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _broadcastService.deleteBroadcast(broadcast.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Broadcast deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        await _loadBroadcasts();
      } catch (e) {
        Logger.error('Failed to delete broadcast: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting broadcast: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}