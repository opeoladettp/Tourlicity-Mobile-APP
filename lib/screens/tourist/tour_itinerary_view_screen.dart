import 'package:flutter/material.dart';
import '../../services/calendar_service.dart';
import '../../services/tour_service.dart';
import '../../utils/logger.dart';
import '../../widgets/common/navigation_drawer.dart' as nav;
import '../../widgets/common/app_bar_actions.dart';
import '../../widgets/common/safe_bottom_padding.dart';
import '../../models/calendar_entry.dart';
import '../../models/registration.dart';

class TourItineraryViewScreen extends StatefulWidget {
  final String? tourId;

  const TourItineraryViewScreen({super.key, this.tourId});

  @override
  State<TourItineraryViewScreen> createState() =>
      _TourItineraryViewScreenState();
}

class _TourItineraryViewScreenState extends State<TourItineraryViewScreen> {
  final CalendarService _calendarService = CalendarService();
  final TourService _tourService = TourService();

  List<Registration> _registrations = [];
  List<CalendarEntry> _calendarEntries = [];

  String? _selectedTourId;
  Registration? _selectedRegistration;

  bool _isLoading = false;
  bool _isLoadingEntries = false;

  @override
  void initState() {
    super.initState();
    _selectedTourId = widget.tourId;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      await _loadRegistrations();
      if (_selectedTourId != null) {
        await _loadCalendarEntries();
      }
    } catch (e) {
      Logger.error('Failed to load initial data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRegistrations() async {
    try {
      final registrations = await _tourService.getMyRegistrations();
      if (mounted) {
        setState(() {
          _registrations = registrations
              .where((r) => r.status == 'approved')
              .toList();

          if (_selectedTourId != null) {
            _selectedRegistration = _registrations.firstWhere(
              (reg) =>
                  (reg.customTour?.id ?? reg.customTourId) == _selectedTourId,
              orElse: () => _registrations.isNotEmpty
                  ? _registrations.first
                  : throw Exception('No registrations found'),
            );
          } else if (_registrations.isNotEmpty) {
            _selectedRegistration = _registrations.first;
            _selectedTourId =
                _selectedRegistration!.customTour?.id ??
                _selectedRegistration!.customTourId;
          }
        });
      }
    } catch (e) {
      Logger.error('Failed to load registrations: $e');
    }
  }

  Future<void> _loadCalendarEntries() async {
    if (_selectedTourId == null) return;

    if (mounted) {
      setState(() => _isLoadingEntries = true);
    }
    try {
      final entries = await _calendarService.getCalendarEntriesForTour(
        _selectedTourId!,
      );
      if (mounted) {
        setState(() {
          _calendarEntries = entries;
          _calendarEntries.sort((a, b) => a.startTime.compareTo(b.startTime));
        });
      }
    } catch (e) {
      Logger.error('Failed to load calendar entries: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingEntries = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tour Itinerary'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [const BothActions()],
      ),
      drawer: nav.NavigationDrawer(currentRoute: '/tour-itinerary-view'),
      body: SafeScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_registrations.isNotEmpty) ...[
              _buildTourSelector(),
              const SizedBox(height: 24),
              if (_selectedRegistration != null) ...[
                _buildTourOverview(),
                const SizedBox(height: 24),
                _buildItinerarySection(),
              ],
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
              hint: const Text('Choose a tour to view'),
              items: _registrations.map((registration) {
                final tour = registration.customTour;
                final tourId = tour?.id ?? registration.customTourId;
                final tourName = tour?.tourName ?? 'Unknown Tour';
                final providerName = tour?.provider?.name ?? 'Unknown Provider';

                return DropdownMenuItem(
                  value: tourId,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(tourName),
                      Text(
                        providerName,
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
                  _selectedRegistration = _registrations.firstWhere(
                    (reg) => (reg.customTour?.id ?? reg.customTourId) == value,
                  );
                });
                _loadCalendarEntries();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTourOverview() {
    final registration = _selectedRegistration!;
    final tour = registration.customTour;
    final tourName = tour?.tourName ?? 'Unknown Tour';
    final providerName = tour?.provider?.name ?? 'Unknown Provider';

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
                    tourName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(registration.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Provider: $providerName',
              style: const TextStyle(color: Colors.grey),
            ),
            if (tour?.startDate != null && tour?.endDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatDate(tour!.startDate)} - ${_formatDate(tour.endDate)}',
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
            ],
            if (registration.notes != null &&
                registration.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.note, size: 16, color: Colors.blue),
                        SizedBox(width: 4),
                        Text(
                          'Your Notes',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      registration.notes!,
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard(
                  'Activities',
                  _calendarEntries.length.toString(),
                  Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Days',
                  tour?.durationDays.toString() ?? '0',
                  Colors.green,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Status',
                  _getStatusDisplayName(registration.status),
                  _getStatusColor(registration.status),
                ),
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              'Your tour provider will add activities to your itinerary soon.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/tour-broadcasts');
              },
              icon: const Icon(Icons.campaign),
              label: const Text('View Tour Messages'),
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
      final date = DateTime(
        entry.startTime.year,
        entry.startTime.month,
        entry.startTime.day,
      );
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${entries.length} ${entries.length == 1 ? 'activity' : 'activities'}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...entries.asMap().entries.map((entry) {
              final index = entry.key;
              final activity = entry.value;
              final isLast = index == entries.length - 1;

              return _buildActivityCard(activity, isLast);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(CalendarEntry entry, bool isLast) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline indicator
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: entry.isDefaultActivity
                        ? Colors.indigo
                        : Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Container(width: 2, height: 40, color: Colors.grey[300]),
              ],
            ),
            const SizedBox(width: 16),
            // Activity content
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (entry.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
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
                      ],
                    ),
                    if (entry.description != null &&
                        entry.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        entry.description!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          entry.timeDisplayText,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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
                      ],
                    ),
                    if (entry.location != null &&
                        entry.location!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              entry.location!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (entry.featuredImage != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          entry.featuredImage!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 120,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        if (!isLast) const SizedBox(height: 16),
      ],
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
            'You haven\'t registered for any tours yet.\nOnce you join a tour, you\'ll see your itinerary here.',
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

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    final label = _getStatusDisplayName(status);

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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'pending':
        return 'Pending';
      case 'rejected':
        return 'Rejected';
      default:
        return status.toUpperCase();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateWithDay(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }
}
