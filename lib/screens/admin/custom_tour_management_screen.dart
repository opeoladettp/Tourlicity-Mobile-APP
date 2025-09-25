import 'package:flutter/material.dart';
import '../../services/custom_tour_service.dart';
import '../../models/custom_tour.dart';
import '../../utils/logger.dart';
import '../../config/routes.dart';
import '../../widgets/common/navigation_drawer.dart' as nav;

class CustomTourManagementScreen extends StatefulWidget {
  const CustomTourManagementScreen({super.key});

  @override
  State<CustomTourManagementScreen> createState() => _CustomTourManagementScreenState();
}

class _CustomTourManagementScreenState extends State<CustomTourManagementScreen> {
  final CustomTourService _customTourService = CustomTourService();
  
  List<CustomTour> _tours = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _statusFilter;

  final List<Map<String, String>> _statusFilters = [
    {'value': '', 'label': 'All Status'},
    {'value': 'draft', 'label': 'Draft'},
    {'value': 'published', 'label': 'Published'},
    {'value': 'active', 'label': 'Active'},
    {'value': 'completed', 'label': 'Completed'},
    {'value': 'cancelled', 'label': 'Cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    _loadTours();
  }

  Future<void> _loadTours() async {
    setState(() => _isLoading = true);
    
    try {
      final tours = await _customTourService.getAllCustomTours(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: _statusFilter?.isNotEmpty == true ? _statusFilter : null,
      );
      setState(() {
        _tours = tours;
      });
    } catch (e) {
      Logger.error('Failed to load custom tours: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading tours: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Tours'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [],
      ),
      drawer: nav.NavigationDrawer(
        currentRoute: AppRoutes.customTourManagement,
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadTours,
                    child: _buildToursList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search tours...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _loadTours();
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Status: '),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusFilters.map((filter) {
                      final isSelected = _statusFilter == filter['value'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter['label']!),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _statusFilter = selected ? filter['value'] : null;
                            });
                            _loadTours();
                          },
                          selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
                          checkmarkColor: const Color(0xFF6366F1),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToursList() {
    if (_tours.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tour, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No tours found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tours.length,
      itemBuilder: (context, index) {
        final tour = _tours[index];
        return _buildTourCard(tour);
      },
    );
  }

  Widget _buildTourCard(CustomTour tour) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                        tour.tourName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Provider: ${tour.provider?.name ?? 'Unknown'}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        '${_formatDate(tour.startDate)} - ${_formatDate(tour.endDate)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(tour.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${tour.registeredTourists}/${tour.maxTourists} tourists',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.qr_code, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Code: ${tour.joinCode}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showTourDetails(tour),
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateTourStatus(tour),
                    icon: const Icon(Icons.edit),
                    label: const Text('Update Status'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
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
    switch (status) {
      case 'draft':
        color = Colors.grey;
        break;
      case 'published':
        color = Colors.blue;
        break;
      case 'active':
        color = Colors.green;
        break;
      case 'completed':
        color = Colors.purple;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  void _showTourDetails(CustomTour tour) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tour.tourName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Provider: ${tour.provider?.name ?? 'Unknown'}'),
              const SizedBox(height: 8),
              Text('Template: ${tour.tourTemplate?.templateName ?? 'Unknown'}'),
              const SizedBox(height: 8),
              Text('Status: ${tour.statusDisplayName}'),
              const SizedBox(height: 8),
              Text('Join Code: ${tour.joinCode}'),
              const SizedBox(height: 8),
              Text('Dates: ${_formatDate(tour.startDate)} - ${_formatDate(tour.endDate)}'),
              const SizedBox(height: 8),
              Text('Tourists: ${tour.registeredTourists}/${tour.maxTourists}'),
              if (tour.groupChatLink != null) ...[
                const SizedBox(height: 8),
                Text('Group Chat: ${tour.groupChatLink}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _updateTourStatus(CustomTour tour) {
    showDialog(
      context: context,
      builder: (context) {
        String selectedStatus = tour.status;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Update Tour Status'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Current status: ${tour.statusDisplayName}'),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'New Status',
                    border: OutlineInputBorder(),
                  ),
                  items: ['draft', 'published', 'active', 'completed', 'cancelled']
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value!;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  
                  try {
                    await _customTourService.updateTourStatus(tour.id, selectedStatus);
                    if (mounted) {
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Tour status updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadTours();
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Update'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}