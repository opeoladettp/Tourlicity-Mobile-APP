import 'package:flutter/material.dart';
import '../../services/calendar_service.dart';
import '../../services/default_activity_service.dart';
import '../../services/custom_tour_service.dart';
import '../../utils/logger.dart';
import '../../widgets/common/navigation_drawer.dart' as nav;
import '../../widgets/common/app_bar_actions.dart';
import '../../widgets/common/safe_bottom_padding.dart';
import '../../models/calendar_entry.dart';
import '../../models/default_activity.dart';
import '../../models/custom_tour.dart';

class TourItineraryManagementScreen extends StatefulWidget {
  final String? tourId;

  const TourItineraryManagementScreen({
    super.key,
    this.tourId,
  });

  @override
  State<TourItineraryManagementScreen> createState() =>
      _TourItineraryManagementScreenState();
}

class _TourItineraryManagementScreenState
    extends State<TourItineraryManagementScreen> {
  final CalendarService _calendarService = CalendarService();
  final DefaultActivityService _activityService = DefaultActivityService();
  final CustomTourService _tourService = CustomTourService();

  List<CustomTour> _tours = [];
  List<CalendarEntry> _calendarEntries = [];
  List<DefaultActivity> _suggestedActivities = [];
  
  String? _selectedTourId;
  CustomTour? _selectedTour;

  bool _isLoadingEntries = false;
  bool _isLoadingSuggestions = false;

  @override
  void initState() {
    super.initState();
    _selectedTourId = widget.tourId;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      await _loadTours();
      if (_selectedTourId != null) {
        await _loadCalendarEntries();
        await _loadSuggestedActivities();
      }
    } catch (e) {
      Logger.error('Failed to load initial data: $e');
    }
  }

  Future<void> _loadTours() async {
    try {
      final tours = await _tourService.getAllCustomTours();
      setState(() {
        _tours = tours.where((tour) => 
          tour.status == 'published' || tour.status == 'active').toList();
        
        if (_selectedTourId != null) {
          _selectedTour = _tours.firstWhere(
            (tour) => tour.id == _selectedTourId,
            orElse: () => _tours.isNotEmpty ? _tours.first : throw Exception('No tours found'),
          );
        } else if (_tours.isNotEmpty) {
          _selectedTour = _tours.first;
          _selectedTourId = _selectedTour!.id;
        }
      });
    } catch (e) {
      Logger.error('Failed to load tours: $e');
    }
  }

  Future<void> _loadCalendarEntries() async {
    if (_selectedTourId == null) return;

    setState(() => _isLoadingEntries = true);
    try {
      final entries = await _calendarService.getCalendarEntriesForTour(_selectedTourId!);
      setState(() {
        _calendarEntries = entries;
        _calendarEntries.sort((a, b) => a.startTime.compareTo(b.startTime));
      });
    } catch (e) {
      Logger.error('Failed to load calendar entries: $e');
    } finally {
      setState(() => _isLoadingEntries = false);
    }
  }

  Future<void> _loadSuggestedActivities() async {
    setState(() => _isLoadingSuggestions = true);
    try {
      final activities = await _activityService.getRecommendedActivitiesForTour(
        tourTemplateId: _selectedTour?.tourTemplate?.id,
        durationDays: _selectedTour?.durationDays,
      );
      setState(() {
        _suggestedActivities = activities;
      });
    } catch (e) {
      Logger.error('Failed to load suggested activities: $e');
    } finally {
      setState(() => _isLoadingSuggestions = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tour Itinerary Management'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [
          const BothActions(),
        ],
      ),
      drawer: nav.NavigationDrawer(
        currentRoute: '/tour-itinerary-management',
      ),
      body: SafeScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTourSelector(),
            const SizedBox(height: 24),
            if (_selectedTour != null) ...[
              _buildTourOverview(),
              const SizedBox(height: 24),
              _buildItinerarySection(),
              const SizedBox(height: 24),
              _buildSuggestedActivitiesSection(),
            ],
          ],
        ),
      ),
      floatingActionButton: _selectedTourId != null
          ? FloatingActionButton.extended(
              onPressed: () => _createNewEntry(),
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Activity'),
            )
          : null,
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedTourId,
              decoration: const InputDecoration(
                labelText: 'Tour',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Choose a tour to manage'),
              items: _tours.map((tour) {
                return DropdownMenuItem(
                  value: tour.id,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(tour.tourName),
                      Text(
                        '${tour.provider?.name ?? 'Unknown Provider'} • ${tour.statusDisplayName}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTourId = value;
                  _selectedTour = _tours.firstWhere((tour) => tour.id == value);
                });
                _loadCalendarEntries();
                _loadSuggestedActivities();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTourOverview() {
    final tour = _selectedTour!;
    
    return Card(
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
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(tour.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Provider: ${tour.provider?.name ?? 'Unknown Provider'}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${_formatDate(tour.startDate)} - ${_formatDate(tour.endDate)}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${tour.durationDays} days',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard('Activities', _calendarEntries.length.toString(), Colors.blue),
                const SizedBox(width: 16),
                _buildStatCard('Template Activities', 
                  _calendarEntries.where((e) => e.isDefaultActivity).length.toString(), 
                  Colors.indigo),
                const SizedBox(width: 16),
                _buildStatCard('Custom Activities', 
                  _calendarEntries.where((e) => !e.isDefaultActivity).length.toString(), 
                  Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItinerarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Itinerary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: _loadCalendarEntries,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh itinerary',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildItineraryContent(),
      ],
    );
  }

  Widget _buildItineraryContent() {
    if (_isLoadingEntries) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_calendarEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_note, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No activities scheduled yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start building your tour itinerary by adding activities.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createNewEntry,
              icon: const Icon(Icons.add),
              label: const Text('Add First Activity'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Group entries by date
    final entriesByDate = <DateTime, List<CalendarEntry>>{};
    for (final entry in _calendarEntries) {
      final date = DateTime(entry.startTime.year, entry.startTime.month, entry.startTime.day);
      entriesByDate.putIfAbsent(date, () => []).add(entry);
    }

    return Column(
      children: entriesByDate.entries.map((dateEntry) {
        return _buildDaySection(dateEntry.key, dateEntry.value);
      }).toList(),
    );
  }

  Widget _buildDaySection(DateTime date, List<CalendarEntry> entries) {
    entries.sort((a, b) => a.startTime.compareTo(b.startTime));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  _formatDateWithDay(date),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${entries.length} ${entries.length == 1 ? 'activity' : 'activities'}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...entries.map((entry) => _buildActivityCard(entry)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(CalendarEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (entry.isDefaultActivity ? Colors.indigo : Colors.green).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  entry.isDefaultActivity ? 'Template' : 'Custom',
                  style: TextStyle(
                    color: entry.isDefaultActivity ? Colors.indigo : Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (entry.category != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    entry.categoryDisplayName,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (value) => _handleActivityAction(value, entry),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (entry.description != null && entry.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              entry.description!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                entry.timeDisplayText,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                entry.durationDisplayText,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              if (entry.location != null && entry.location!.isNotEmpty) ...[
                const SizedBox(width: 16),
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    entry.location!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Suggested Activities',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Popular activity templates you can add to your itinerary',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        _buildSuggestedActivitiesContent(),
      ],
    );
  }

  Widget _buildSuggestedActivitiesContent() {
    if (_isLoadingSuggestions) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_suggestedActivities.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.grey[600]),
              const SizedBox(width: 8),
              const Text('No activity suggestions available at the moment.'),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _suggestedActivities.length,
        itemBuilder: (context, index) {
          final activity = _suggestedActivities[index];
          return _buildSuggestedActivityCard(activity);
        },
      ),
    );
  }

  Widget _buildSuggestedActivityCard(DefaultActivity activity) {
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      activity.categoryDisplayName,
                      style: const TextStyle(
                        color: Colors.indigo,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    activity.durationDisplayText,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                activity.activityName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  activity.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _addSuggestedActivity(activity),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add to Itinerary'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
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
      case 'active':
        color = Colors.blue;
        label = 'Active';
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateWithDay(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  void _createNewEntry() {
    Navigator.pushNamed(
      context, 
      '/enhanced-calendar-entry',
      arguments: {'tourId': _selectedTourId},
    ).then((result) {
      if (result == true) {
        _loadCalendarEntries();
      }
    });
  }

  void _addSuggestedActivity(DefaultActivity activity) {
    // Navigate to calendar entry screen with pre-selected activity
    Navigator.pushNamed(
      context,
      '/enhanced-calendar-entry',
      arguments: {
        'tourId': _selectedTourId,
        'activityId': activity.id,
        'entryType': 'default',
      },
    ).then((result) {
      if (result == true) {
        _loadCalendarEntries();
      }
    });
  }

  void _handleActivityAction(String action, CalendarEntry entry) {
    switch (action) {
      case 'edit':
        Navigator.pushNamed(
          context,
          '/enhanced-calendar-entry',
          arguments: {
            'tourId': _selectedTourId,
            'existingEntry': entry,
          },
        ).then((result) {
          if (result == true) {
            _loadCalendarEntries();
          }
        });
        break;
      case 'delete':
        _deleteActivity(entry);
        break;
    }
  }

  Future<void> _deleteActivity(CalendarEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: Text(
          'Are you sure you want to delete "${entry.title}"?\n\n'
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
        await _calendarService.deleteCalendarEntry(entry.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activity deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        _loadCalendarEntries();
      } catch (e) {
        Logger.error('Failed to delete activity: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting activity: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}