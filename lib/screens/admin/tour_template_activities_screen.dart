import 'package:flutter/material.dart';
import '../../services/calendar_service.dart';
import '../../services/tour_template_service.dart';
import '../../models/calendar_entry.dart';
import '../../models/tour_template.dart';
import '../../models/default_activity.dart';
import '../../utils/logger.dart';
import '../../widgets/common/navigation_drawer.dart' as nav;
import '../../widgets/common/app_bar_actions.dart';
import '../../widgets/common/safe_bottom_padding.dart';

class TourTemplateActivitiesScreen extends StatefulWidget {
  final String templateId;

  const TourTemplateActivitiesScreen({super.key, required this.templateId});

  @override
  State<TourTemplateActivitiesScreen> createState() =>
      _TourTemplateActivitiesScreenState();
}

class _TourTemplateActivitiesScreenState
    extends State<TourTemplateActivitiesScreen> {
  final CalendarService _calendarService = CalendarService();
  final TourTemplateService _tourTemplateService = TourTemplateService();

  TourTemplate? _template;
  List<CalendarEntry> _activities = [];
  List<DefaultActivity> _defaultActivities = [];
  bool _isLoading = true;
  bool _isLoadingDefaults = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      // Load template details
      final template = await _tourTemplateService.getTourTemplateById(
        widget.templateId,
      );

      // Load template activities (calendar entries for this template)
      final activities = await _calendarService.getCalendarEntries();
      final templateActivities = activities
          .where(
            (activity) =>
                activity.customTourId == widget.templateId ||
                activity.isDefaultActivity,
          )
          .toList();

      if (mounted) {
        setState(() {
          _template = template;
          _activities = templateActivities;
        });
      }
    } catch (e) {
      Logger.error('Failed to load template activities: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading activities: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadDefaultActivities() async {
    if (mounted) {
      setState(() => _isLoadingDefaults = true);
    }
    try {
      final defaults = await _calendarService.getDefaultActivities();
      if (mounted) {
        setState(() {
          _defaultActivities = defaults;
        });
      }
    } catch (e) {
      Logger.error('Failed to load default activities: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingDefaults = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_template?.templateName ?? 'Template Activities'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [const BothActions()],
      ),
      drawer: nav.NavigationDrawer(
        currentRoute: '/tour-template-activities/${widget.templateId}',
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateActivityDialog(),
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(onRefresh: _loadData, child: _buildContent()),
    );
  }

  Widget _buildContent() {
    return SafeScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_template != null) _buildTemplateInfo(),
          const SizedBox(height: 24),
          _buildActivitiesSection(),
          const SizedBox(height: 24),
          _buildDefaultActivitiesSection(),
        ],
      ),
    );
  }

  Widget _buildTemplateInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _template!.templateName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${_template!.durationDays} days • ${_formatDate(_template!.startDate)} - ${_formatDate(_template!.endDate)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(_template!.description),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Template Activities',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (_activities.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.event_note, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No activities added yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _showCreateActivityDialog(),
                      child: const Text('Add First Activity'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ..._activities.map((activity) => _buildActivityCard(activity)),
      ],
    );
  }

  Widget _buildDefaultActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Default Activities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _loadDefaultActivities,
              icon: _isLoadingDefaults
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: const Text('Load Defaults'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_defaultActivities.isEmpty && !_isLoadingDefaults)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No default activities available',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          )
        else
          ..._defaultActivities.map(
            (activity) => _buildDefaultActivitySelectionCard(activity),
          ),
      ],
    );
  }

  Widget _buildActivityCard(CalendarEntry activity) {
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
                  child: Text(
                    activity.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (activity.isDefaultActivity)
                  const Chip(
                    label: Text('Default'),
                    backgroundColor: Colors.blue,
                    labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                  ),
              ],
            ),
            if (activity.description != null) ...[
              const SizedBox(height: 8),
              Text(activity.description!),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${_formatDateTime(activity.startTime)} - ${_formatDateTime(activity.endTime)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            if (activity.location != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    activity.location!,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditActivityDialog(activity),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _deleteActivity(activity),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
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

  Widget _buildDefaultActivitySelectionCard(DefaultActivity activity) {
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
                  child: Text(
                    activity.activityName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _addDefaultActivityToTemplate(activity),
                  icon: const Icon(Icons.add),
                  label: const Text('Add to Template'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(activity.description),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.category, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  activity.categoryDisplayName,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  activity.durationDisplayText,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateActivityDialog() async {
    await _showActivityDialog();
  }

  Future<void> _showEditActivityDialog(CalendarEntry activity) async {
    await _showActivityDialog(activity: activity);
  }

  Future<void> _showActivityDialog({CalendarEntry? activity}) async {
    final titleController = TextEditingController(text: activity?.title ?? '');
    final descriptionController = TextEditingController(
      text: activity?.description ?? '',
    );
    final locationController = TextEditingController(
      text: activity?.location ?? '',
    );

    DateTime startTime = activity?.startTime ?? DateTime.now();
    DateTime endTime =
        activity?.endTime ?? DateTime.now().add(const Duration(hours: 1));

    String activityType = activity?.activityType ?? 'sightseeing';
    String? titleError;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(activity == null ? 'Add Activity' : 'Edit Activity'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Activity Title *',
                    border: const OutlineInputBorder(),
                    errorText: titleError,
                  ),
                  onChanged: (value) {
                    setState(() {
                      titleError = value.trim().isEmpty
                          ? 'Title is required'
                          : null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: activityType,
                  decoration: const InputDecoration(
                    labelText: 'Activity Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'sightseeing',
                      child: Text('Sightseeing'),
                    ),
                    DropdownMenuItem(value: 'dining', child: Text('Dining')),
                    DropdownMenuItem(
                      value: 'transportation',
                      child: Text('Transportation'),
                    ),
                    DropdownMenuItem(
                      value: 'accommodation',
                      child: Text('Accommodation'),
                    ),
                    DropdownMenuItem(
                      value: 'entertainment',
                      child: Text('Entertainment'),
                    ),
                    DropdownMenuItem(
                      value: 'shopping',
                      child: Text('Shopping'),
                    ),
                    DropdownMenuItem(
                      value: 'cultural',
                      child: Text('Cultural'),
                    ),
                    DropdownMenuItem(
                      value: 'adventure',
                      child: Text('Adventure'),
                    ),
                    DropdownMenuItem(
                      value: 'relaxation',
                      child: Text('Relaxation'),
                    ),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        activityType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Start Time'),
                        subtitle: Text(_formatDateTime(startTime)),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startTime,
                            firstDate: _template?.startDate ?? DateTime.now(),
                            lastDate:
                                _template?.endDate ??
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null && context.mounted) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(startTime),
                            );
                            if (time != null && context.mounted) {
                              setState(() {
                                startTime = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text('End Time'),
                        subtitle: Text(_formatDateTime(endTime)),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endTime,
                            firstDate: startTime,
                            lastDate:
                                _template?.endDate ??
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null && context.mounted) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(endTime),
                            );
                            if (time != null && context.mounted) {
                              setState(() {
                                endTime = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
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

                // Validate title
                if (titleController.text.trim().isEmpty) {
                  setState(() {
                    titleError = 'Title is required';
                  });
                  return;
                }

                // Validate time order
                if (endTime.isBefore(startTime)) {
                  // Show validation error in the current dialog
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('End time must be after start time'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 3),
                    ),
                  );
                  return;
                }

                try {
                  if (activity == null) {
                    await _calendarService.createCalendarEntry(
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                      startTime: startTime,
                      endTime: endTime,
                      location: locationController.text.trim().isEmpty
                          ? null
                          : locationController.text.trim(),
                      activityType: activityType,
                      customTourId: widget.templateId,
                      isDefaultActivity: false,
                    );
                  } else {
                    await _calendarService.updateCalendarEntry(
                      activity.id,
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                      startTime: startTime,
                      endTime: endTime,
                      location: locationController.text.trim().isEmpty
                          ? null
                          : locationController.text.trim(),
                      activityType: activityType,
                    );
                  }

                  if (mounted) {
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          activity == null
                              ? 'Activity added successfully'
                              : 'Activity updated successfully',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadData();
                  }
                } catch (e) {
                  Logger.error('Failed to create/update activity: $e');
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
              child: Text(activity == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addDefaultActivityToTemplate(dynamic activity) async {
    try {
      if (activity is DefaultActivity) {
        // Calculate end time based on activity duration
        final startTime = _template!.startDate.add(
          const Duration(hours: 9),
        ); // Default to 9 AM on first day
        final endTime = activity.calculateEndTime(startTime);

        await _calendarService.createCalendarEntry(
          title: activity.activityName,
          description: activity.description,
          startTime: startTime,
          endTime: endTime,
          location: null, // DefaultActivity doesn't have location
          activityType: 'default',
          customTourId: widget.templateId,
          isDefaultActivity: true,
        );
      } else if (activity is CalendarEntry) {
        await _calendarService.createCalendarEntry(
          title: activity.title,
          description: activity.description,
          startTime: _template!.startDate.add(
            const Duration(hours: 9),
          ), // Default to 9 AM on first day
          endTime: _template!.startDate.add(
            const Duration(hours: 10),
          ), // 1 hour duration
          location: activity.location,
          activityType: activity.activityType,
          customTourId: widget.templateId,
          isDefaultActivity: false,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default activity added to template'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding activity: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteActivity(CalendarEntry activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: Text('Are you sure you want to delete "${activity.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _calendarService.deleteCalendarEntry(activity.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activity deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
