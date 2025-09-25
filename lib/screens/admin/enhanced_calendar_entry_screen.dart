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

class EnhancedCalendarEntryScreen extends StatefulWidget {
  final String? tourId;
  final CalendarEntry? existingEntry;

  const EnhancedCalendarEntryScreen({
    super.key,
    this.tourId,
    this.existingEntry,
  });

  @override
  State<EnhancedCalendarEntryScreen> createState() =>
      _EnhancedCalendarEntryScreenState();
}

class _EnhancedCalendarEntryScreenState
    extends State<EnhancedCalendarEntryScreen> {
  final CalendarService _calendarService = CalendarService();
  final DefaultActivityService _activityService = DefaultActivityService();
  final CustomTourService _tourService = CustomTourService();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 2);

  String _entryType = 'custom'; // 'custom' or 'default'
  String? _selectedTourId;
  String? _selectedActivityId;
  String? _selectedCategory;

  List<CustomTour> _tours = [];
  List<DefaultActivity> _defaultActivities = [];
  List<ActivityCategory> _categories = [];
  List<CalendarEntry> _conflicts = [];

  bool _isSaving = false;
  bool _isLoadingActivities = false;

  @override
  void initState() {
    super.initState();
    _selectedTourId = widget.tourId;
    _loadInitialData();
    
    if (widget.existingEntry != null) {
      _populateExistingEntry();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _populateExistingEntry() {
    final entry = widget.existingEntry!;
    _titleController.text = entry.title;
    _descriptionController.text = entry.description ?? '';
    _locationController.text = entry.location ?? '';
    
    _selectedDate = DateTime(entry.startTime.year, entry.startTime.month, entry.startTime.day);
    _startTime = TimeOfDay.fromDateTime(entry.startTime);
    _endTime = TimeOfDay.fromDateTime(entry.endTime);
    
    _entryType = entry.isDefaultActivity ? 'default' : 'custom';
    _selectedTourId = entry.customTourId;
    _selectedActivityId = entry.defaultActivityId;
    _selectedCategory = entry.category;
  }

  Future<void> _loadInitialData() async {
    try {
      await Future.wait([
        _loadTours(),
        _loadCategories(),
        if (_entryType == 'default') _loadDefaultActivities(),
      ]);
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
      });
    } catch (e) {
      Logger.error('Failed to load tours: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _activityService.getActivityCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      Logger.error('Failed to load categories: $e');
    }
  }

  Future<void> _loadDefaultActivities() async {
    setState(() => _isLoadingActivities = true);
    try {
      final activities = await _activityService.getActivitiesForSelection(
        category: _selectedCategory,
      );
      setState(() {
        _defaultActivities = activities;
      });
    } catch (e) {
      Logger.error('Failed to load default activities: $e');
    } finally {
      setState(() => _isLoadingActivities = false);
    }
  }

  Future<void> _checkForConflicts() async {
    if (_selectedTourId == null) return;

    try {
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      
      final endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      final conflicts = await _calendarService.checkForConflicts(
        startTime: startDateTime,
        endTime: endDateTime,
        tourId: _selectedTourId,
        excludeEntryId: widget.existingEntry?.id,
      );

      setState(() {
        _conflicts = conflicts;
      });
    } catch (e) {
      Logger.error('Failed to check for conflicts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingEntry != null ? 'Edit Calendar Entry' : 'New Calendar Entry'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [
          const BothActions(),
        ],
      ),
      drawer: nav.NavigationDrawer(
        currentRoute: '/calendar-entry',
      ),
      body: SafeScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEntryTypeSelector(),
            const SizedBox(height: 24),
            _buildTourSelector(),
            const SizedBox(height: 24),
            if (_entryType == 'default') ...[
              _buildCategorySelector(),
              const SizedBox(height: 16),
              _buildActivitySelector(),
              const SizedBox(height: 24),
            ],
            _buildBasicFields(),
            const SizedBox(height: 24),
            _buildDateTimeFields(),
            const SizedBox(height: 24),
            if (_conflicts.isNotEmpty) _buildConflictsWarning(),
            const SizedBox(height: 24),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entry Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'custom',
                  label: Text('Custom Activity'),
                  icon: Icon(Icons.edit),
                ),
                ButtonSegment(
                  value: 'default',
                  label: Text('Template Activity'),
                  icon: Icon(Icons.library_books),
                ),
              ],
              selected: {_entryType},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  _entryType = selection.first;
                  _selectedActivityId = null;
                  if (_entryType == 'default') {
                    _loadDefaultActivities();
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (_entryType == 'default' ? Colors.indigo : Colors.blue).withValues(alpha: 0.1),
                border: Border.all(color: (_entryType == 'default' ? Colors.indigo : Colors.blue).withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _entryType == 'default' ? Icons.info : Icons.lightbulb,
                    color: _entryType == 'default' ? Colors.indigo : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _entryType == 'default'
                          ? 'Template activities use predefined details and durations from the activity library.'
                          : 'Custom activities allow you to create unique entries with your own details.',
                      style: TextStyle(
                        color: _entryType == 'default' ? Colors.indigo : Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
              'Tour Selection',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedTourId,
              decoration: const InputDecoration(
                labelText: 'Select Tour',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Choose a tour for this activity'),
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
                });
                _checkForConflicts();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Activity Category',
        border: OutlineInputBorder(),
      ),
      hint: const Text('Select category to filter activities'),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('All Categories'),
        ),
        ..._categories.map((category) {
          return DropdownMenuItem<String>(
            value: category.name,
            child: Text('${category.displayName} (${category.count})'),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
          _selectedActivityId = null;
        });
        _loadDefaultActivities();
      },
    );
  }

  Widget _buildActivitySelector() {
    if (_isLoadingActivities) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_defaultActivities.isEmpty) {
      return Card(
        color: Colors.orange[50],
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('No activities available for the selected category.'),
            ],
          ),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedActivityId,
      decoration: const InputDecoration(
        labelText: 'Select Activity Template',
        border: OutlineInputBorder(),
      ),
      hint: const Text('Choose an activity template'),
      items: _defaultActivities.map((activity) {
        return DropdownMenuItem(
          value: activity.id,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(activity.activityName),
              Text(
                '${activity.categoryDisplayName} • ${activity.durationDisplayText}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedActivityId = value;
        });
        _populateFromDefaultActivity();
      },
    );
  }

  void _populateFromDefaultActivity() {
    if (_selectedActivityId == null) return;

    final activity = _defaultActivities.firstWhere(
      (a) => a.id == _selectedActivityId,
      orElse: () => _defaultActivities.first,
    );

    setState(() {
      _titleController.text = activity.activityName;
      _descriptionController.text = activity.description;
      
      // Calculate end time based on duration
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      
      final endDateTime = activity.calculateEndTime(startDateTime);
      _endTime = TimeOfDay.fromDateTime(endDateTime);
    });

    _checkForConflicts();
  }

  Widget _buildBasicFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Activity Title',
                border: OutlineInputBorder(),
              ),
              enabled: _entryType == 'custom' || _selectedActivityId == null,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date & Time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              ),
              onTap: _selectDate,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Start Time'),
              subtitle: Text(_startTime.format(context)),
              onTap: () => _selectTime(true),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.access_time_filled),
              title: const Text('End Time'),
              subtitle: Text(_endTime.format(context)),
              onTap: () => _selectTime(false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConflictsWarning() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Scheduling Conflicts Detected',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'This time slot conflicts with ${_conflicts.length} existing ${_conflicts.length == 1 ? 'activity' : 'activities'}:',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 8),
            ..._conflicts.map((conflict) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Text(
                '• ${conflict.title} (${conflict.timeDisplayText})',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final canSave = _titleController.text.trim().isNotEmpty &&
                   _selectedTourId != null &&
                   (_entryType == 'custom' || _selectedActivityId != null);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canSave && !_isSaving ? _saveEntry : null,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(widget.existingEntry != null ? Icons.save : Icons.add),
        label: Text(_isSaving 
            ? 'Saving...' 
            : widget.existingEntry != null 
                ? 'Update Entry' 
                : 'Create Entry'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
      _checkForConflicts();
    }
  }

  Future<void> _selectTime(bool isStartTime) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );

    if (time != null) {
      setState(() {
        if (isStartTime) {
          _startTime = time;
          // Auto-adjust end time if it's before start time
          if (_endTime.hour < _startTime.hour || 
              (_endTime.hour == _startTime.hour && _endTime.minute <= _startTime.minute)) {
            _endTime = TimeOfDay(
              hour: (_startTime.hour + 2) % 24,
              minute: _startTime.minute,
            );
          }
        } else {
          _endTime = time;
        }
      });
      _checkForConflicts();
    }
  }

  Future<void> _saveEntry() async {
    setState(() => _isSaving = true);

    try {
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      
      final endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      if (widget.existingEntry != null) {
        // Update existing entry
        await _calendarService.updateCalendarEntry(
          widget.existingEntry!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty 
              ? _descriptionController.text.trim() 
              : null,
          startTime: startDateTime,
          endTime: endDateTime,
          location: _locationController.text.trim().isNotEmpty 
              ? _locationController.text.trim() 
              : null,
          activityType: _entryType,
        );
      } else {
        // Create new entry
        if (_entryType == 'default' && _selectedActivityId != null) {
          await _calendarService.createCalendarEntryFromDefaultActivity(
            defaultActivityId: _selectedActivityId!,
            startTime: startDateTime,
            customTourId: _selectedTourId!,
            location: _locationController.text.trim().isNotEmpty 
                ? _locationController.text.trim() 
                : null,
            customDescription: _descriptionController.text.trim().isNotEmpty 
                ? _descriptionController.text.trim() 
                : null,
          );
        } else {
          await _calendarService.createCalendarEntry(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isNotEmpty 
                ? _descriptionController.text.trim() 
                : null,
            startTime: startDateTime,
            endTime: endDateTime,
            location: _locationController.text.trim().isNotEmpty 
                ? _locationController.text.trim() 
                : null,
            activityType: _entryType,
            customTourId: _selectedTourId!,
            isDefaultActivity: _entryType == 'default',
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingEntry != null 
                ? 'Calendar entry updated successfully!' 
                : 'Calendar entry created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      Logger.error('Failed to save calendar entry: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving calendar entry: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }
}