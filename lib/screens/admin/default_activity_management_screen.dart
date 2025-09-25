import 'package:flutter/material.dart';
import '../../services/default_activity_service.dart';
import '../../utils/logger.dart';
import '../../widgets/common/navigation_drawer.dart' as nav;
import '../../widgets/common/app_bar_actions.dart';
import '../../widgets/common/safe_bottom_padding.dart';
import '../../models/default_activity.dart';

class DefaultActivityManagementScreen extends StatefulWidget {
  const DefaultActivityManagementScreen({super.key});

  @override
  State<DefaultActivityManagementScreen> createState() =>
      _DefaultActivityManagementScreenState();
}

class _DefaultActivityManagementScreenState
    extends State<DefaultActivityManagementScreen> {
  final DefaultActivityService _activityService = DefaultActivityService();

  List<DefaultActivity> _activities = [];
  List<ActivityCategory> _categories = [];
  String? _selectedCategory;
  String _searchQuery = '';
  bool _showActiveOnly = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([_loadActivities(), _loadCategories()]);
    } catch (e) {
      Logger.error('Failed to load data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadActivities() async {
    try {
      final activities = await _activityService.getAllDefaultActivities(
        category: _selectedCategory,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        isActive: _showActiveOnly ? true : null,
      );
      setState(() {
        _activities = activities;
      });
    } catch (e) {
      Logger.error('Failed to load activities: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading activities: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  List<DefaultActivity> get _filteredActivities {
    return _activities;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Templates'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [const BothActions()],
      ),
      drawer: nav.NavigationDrawer(
        currentRoute: '/default-activity-management',
      ),
      body: SafeScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilters(),
            const SizedBox(height: 24),
            _buildCategoriesOverview(),
            const SizedBox(height: 24),
            _buildActivitiesList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewActivity,
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Template'),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search activities',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by name or description',
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _loadActivities();
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('All categories'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All categories'),
                      ),
                      ..._categories.map((category) {
                        return DropdownMenuItem<String?>(
                          value: category.name,
                          child: Text(
                            '${category.displayName} (${category.count})',
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                      _loadActivities();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 140,
                  child: SwitchListTile(
                    title: const Text('Active Only'),
                    value: _showActiveOnly,
                    onChanged: (value) {
                      setState(() {
                        _showActiveOnly = value;
                      });
                      _loadActivities();
                    },
                    dense: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesOverview() {
    if (_categories.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Categories Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category.name;
                return FilterChip(
                  label: Text('${category.displayName} (${category.count})'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? category.name : null;
                    });
                    _loadActivities();
                  },
                  backgroundColor: Colors.grey[100],
                  selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
                  checkmarkColor: const Color(0xFF6366F1),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final filteredActivities = _filteredActivities;

    if (filteredActivities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.library_books, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _activities.isEmpty
                  ? 'No activity templates yet'
                  : 'No activities match your filters',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              _activities.isEmpty
                  ? 'Create your first activity template to help providers build better tours'
                  : 'Try adjusting your search or filters',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (_activities.isEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _createNewActivity,
                icon: const Icon(Icons.add),
                label: const Text('Create First Template'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Templates (${filteredActivities.length})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredActivities.length,
          itemBuilder: (context, index) {
            final activity = filteredActivities[index];
            return _buildActivityCard(activity);
          },
        ),
      ],
    );
  }

  Widget _buildActivityCard(DefaultActivity activity) {
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
                        activity.activityName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
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
                              activity.categoryDisplayName,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              activity.durationDisplayText,
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(activity.isActive),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleActivityAction(value, activity),
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
                    PopupMenuItem(
                      value: 'toggle_status',
                      child: Row(
                        children: [
                          Icon(
                            activity.isActive
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(activity.isActive ? 'Deactivate' : 'Activate'),
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
            const SizedBox(height: 12),
            Text(
              activity.description,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Typical duration: ${activity.durationDisplayText}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (activity.createdBy != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Created by: ${activity.createdBy!.fullName}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isActive) {
    final color = isActive ? Colors.green : Colors.grey;
    final label = isActive ? 'Active' : 'Inactive';

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

  void _createNewActivity() {
    _showActivityDialog();
  }

  void _handleActivityAction(String action, DefaultActivity activity) {
    switch (action) {
      case 'edit':
        _showActivityDialog(activity: activity);
        break;
      case 'toggle_status':
        _toggleActivityStatus(activity);
        break;
      case 'delete':
        _deleteActivity(activity);
        break;
    }
  }

  void _showActivityDialog({DefaultActivity? activity}) {
    final isEditing = activity != null;
    final nameController = TextEditingController(
      text: activity?.activityName ?? '',
    );
    final descriptionController = TextEditingController(
      text: activity?.description ?? '',
    );
    final durationController = TextEditingController(
      text: activity?.typicalDurationHours.toString() ?? '2.0',
    );
    String selectedCategory = activity?.category ?? 'sightseeing';
    bool isActive = activity?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            isEditing ? 'Edit Activity Template' : 'Create Activity Template',
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Activity Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: durationController,
                        decoration: const InputDecoration(
                          labelText: 'Duration (hours)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'sightseeing',
                            child: Text('Sightseeing'),
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
                            value: 'dining',
                            child: Text('Dining'),
                          ),
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
                            value: 'educational',
                            child: Text('Educational'),
                          ),
                          DropdownMenuItem(
                            value: 'religious',
                            child: Text('Religious'),
                          ),
                          DropdownMenuItem(
                            value: 'nature',
                            child: Text('Nature'),
                          ),
                          DropdownMenuItem(
                            value: 'other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedCategory = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: const Text('Available for use in tours'),
                  value: isActive,
                  onChanged: (value) {
                    setDialogState(() {
                      isActive = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _saveActivity(
                context,
                activity?.id,
                nameController.text,
                descriptionController.text,
                double.tryParse(durationController.text) ?? 2.0,
                selectedCategory,
                isActive,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveActivity(
    BuildContext dialogContext,
    String? activityId,
    String name,
    String description,
    double duration,
    String category,
    bool isActive,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(dialogContext);

    if (name.trim().isEmpty || description.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      if (activityId != null) {
        // Update existing activity
        await _activityService.updateDefaultActivity(
          id: activityId,
          activityName: name.trim(),
          description: description.trim(),
          typicalDurationHours: duration,
          category: category,
          isActive: isActive,
        );
      } else {
        // Create new activity
        await _activityService.createDefaultActivity(
          activityName: name.trim(),
          description: description.trim(),
          typicalDurationHours: duration,
          category: category,
          isActive: isActive,
        );
      }

      // Use the captured navigator reference to safely pop the dialog
      if (navigator.canPop()) {
        navigator.pop();
      }

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              activityId != null
                  ? 'Activity template updated successfully!'
                  : 'Activity template created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      _loadData();
    } catch (e) {
      Logger.error('Failed to save activity: $e');
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error saving activity: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleActivityStatus(DefaultActivity activity) async {
    try {
      await _activityService.toggleActivityStatus(activity.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Activity ${activity.isActive ? 'deactivated' : 'activated'} successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      _loadActivities();
    } catch (e) {
      Logger.error('Failed to toggle activity status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating activity: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteActivity(DefaultActivity activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity Template'),
        content: Text(
          'Are you sure you want to delete "${activity.activityName}"?\n\n'
          'This action cannot be undone and may affect existing tours that use this template.',
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
        await _activityService.deleteDefaultActivity(activity.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activity template deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }

        _loadData();
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
