import '../models/calendar_entry.dart';
import '../models/default_activity.dart';
import 'api_service.dart';
import 'default_activity_service.dart';
import '../utils/logger.dart';

class CalendarService {
  final ApiService _apiService = ApiService();
  final DefaultActivityService _defaultActivityService = DefaultActivityService();

  Future<List<CalendarEntry>> getCalendarEntries() async {
    try {
      final response = await _apiService.get('/calendar');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => CalendarEntry.fromJson(json)).toList();
      }
      throw Exception('Failed to load calendar entries');
    } catch (e) {
      Logger.warning('⚠️ API call failed, returning empty calendar list: $e');
      return [];
    }
  }

  /// Get default activities for calendar entry creation
  Future<List<DefaultActivity>> getDefaultActivitiesForCalendar() async {
    try {
      final response = await _apiService.get('/calendar/default-activities');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['activities'] ?? response.data['data'] ?? [];
        return data.map((json) => DefaultActivity.fromJson(json)).toList();
      }
      throw Exception('Failed to load default activities');
    } catch (e) {
      Logger.warning('⚠️ API call failed, returning empty activities list: $e');
      return [];
    }
  }

  /// Get default activities (alias for compatibility)
  Future<List<DefaultActivity>> getDefaultActivities() async {
    return await _defaultActivityService.getAllDefaultActivities();
  }

  Future<CalendarEntry> getCalendarEntryById(String id) async {
    final response = await _apiService.get('/calendar/$id');
    if (response.statusCode == 200) {
      return CalendarEntry.fromJson(response.data['entry'] ?? response.data);
    }
    throw Exception('Failed to load calendar entry');
  }

  Future<CalendarEntry> createCalendarEntry({
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    String? activityType,
    String? customTourId,
    String? defaultActivityId,
    String? category,
    bool isDefaultActivity = false,
  }) async {
    final response = await _apiService.post(
      '/calendar',
      data: {
        'title': title,
        if (description != null) 'description': description,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        if (location != null) 'location': location,
        if (activityType != null) 'activity_type': activityType,
        if (customTourId != null) 'custom_tour_id': customTourId,
        if (defaultActivityId != null) 'default_activity_id': defaultActivityId,
        if (category != null) 'category': category,
        'is_default_activity': isDefaultActivity,
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return CalendarEntry.fromJson(response.data['entry'] ?? response.data);
    }
    throw Exception('Failed to create calendar entry');
  }

  Future<CalendarEntry> updateCalendarEntry(
    String id, {
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? activityType,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (startTime != null) data['start_time'] = startTime.toIso8601String();
    if (endTime != null) data['end_time'] = endTime.toIso8601String();
    if (location != null) data['location'] = location;
    if (activityType != null) data['activity_type'] = activityType;

    final response = await _apiService.put('/calendar/$id', data: data);
    if (response.statusCode == 200) {
      return CalendarEntry.fromJson(response.data['entry'] ?? response.data);
    }
    throw Exception('Failed to update calendar entry');
  }

  Future<void> deleteCalendarEntry(String id) async {
    final response = await _apiService.delete('/calendar/$id');
    if (response.statusCode != 200) {
      throw Exception('Failed to delete calendar entry');
    }
  }

  /// Create calendar entry from default activity template
  Future<CalendarEntry> createCalendarEntryFromDefaultActivity({
    required String defaultActivityId,
    required DateTime startTime,
    required String customTourId,
    String? location,
    String? customDescription,
  }) async {
    try {
      // Get the default activity details
      final defaultActivity = await _defaultActivityService.getDefaultActivityById(defaultActivityId);
      
      // Calculate end time based on typical duration
      final endTime = defaultActivity.calculateEndTime(startTime);
      
      // Use default activity data to populate calendar entry
      return await createCalendarEntry(
        title: defaultActivity.activityName,
        description: customDescription ?? defaultActivity.description,
        startTime: startTime,
        endTime: endTime,
        location: location,
        activityType: 'default',
        customTourId: customTourId,
        defaultActivityId: defaultActivityId,
        category: defaultActivity.category,
        isDefaultActivity: true,
      );
    } catch (e) {
      Logger.error('Failed to create calendar entry from default activity: $e');
      rethrow;
    }
  }

  /// Get calendar entries for a specific tour
  Future<List<CalendarEntry>> getCalendarEntriesForTour(String tourId) async {
    try {
      final queryParams = {'custom_tour_id': tourId};
      final response = await _apiService.get('/calendar', queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => CalendarEntry.fromJson(json)).toList();
      }
      throw Exception('Failed to load calendar entries for tour');
    } catch (e) {
      Logger.warning('⚠️ API call failed, returning empty calendar list: $e');
      return [];
    }
  }

  /// Get calendar entries for a specific date range
  Future<List<CalendarEntry>> getCalendarEntriesForDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? tourId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        if (tourId != null) 'custom_tour_id': tourId,
      };
      
      final response = await _apiService.get('/calendar', queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => CalendarEntry.fromJson(json)).toList();
      }
      throw Exception('Failed to load calendar entries for date range');
    } catch (e) {
      Logger.warning('⚠️ API call failed, returning empty calendar list: $e');
      return [];
    }
  }

  /// Upload featured image for calendar entry
  Future<String> uploadFeaturedImage(String entryId, String imagePath) async {
    try {
      final response = await _apiService.post(
        '/calendar/$entryId/featured-image',
        data: {'featured_image': imagePath},
      );
      
      if (response.statusCode == 200) {
        return response.data['featured_image'] ?? '';
      }
      throw Exception('Failed to upload featured image');
    } catch (e) {
      Logger.error('Failed to upload featured image: $e');
      rethrow;
    }
  }

  /// Delete featured image for calendar entry
  Future<void> deleteFeaturedImage(String entryId) async {
    try {
      final response = await _apiService.delete('/calendar/$entryId/featured-image');
      
      if (response.statusCode != 200) {
        throw Exception('Failed to delete featured image');
      }
    } catch (e) {
      Logger.error('Failed to delete featured image: $e');
      rethrow;
    }
  }

  /// Get presigned URL for image upload
  Future<Map<String, dynamic>> getPresignedUrl({
    required String fileName,
    required String contentType,
  }) async {
    try {
      final response = await _apiService.post(
        '/calendar/presigned-url',
        data: {
          'fileName': fileName,
          'contentType': contentType,
        },
      );
      
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to get presigned URL');
    } catch (e) {
      Logger.error('Failed to get presigned URL: $e');
      rethrow;
    }
  }

  /// Update calendar entry with presigned image
  Future<void> updateWithPresignedImage({
    required String entryId,
    required String imageUrl,
  }) async {
    try {
      final response = await _apiService.put(
        '/calendar/$entryId/presigned-image',
        data: {'imageUrl': imageUrl},
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update with presigned image');
      }
    } catch (e) {
      Logger.error('Failed to update with presigned image: $e');
      rethrow;
    }
  }

  /// Check for scheduling conflicts
  Future<List<CalendarEntry>> checkForConflicts({
    required DateTime startTime,
    required DateTime endTime,
    String? tourId,
    String? excludeEntryId,
  }) async {
    try {
      final entries = await getCalendarEntriesForDateRange(
        startDate: startTime,
        endDate: endTime,
        tourId: tourId,
      );
      
      return entries.where((entry) {
        if (excludeEntryId != null && entry.id == excludeEntryId) {
          return false; // Exclude the entry being updated
        }
        return entry.startTime.isBefore(endTime) && entry.endTime.isAfter(startTime);
      }).toList();
    } catch (e) {
      Logger.error('Failed to check for conflicts: $e');
      return [];
    }
  }

  /// Get activity suggestions based on time slot and tour context
  Future<List<DefaultActivity>> getActivitySuggestions({
    required DateTime startTime,
    required DateTime endTime,
    String? category,
    String? tourId,
  }) async {
    try {
      final activities = await _defaultActivityService.getActivitiesForSelection(
        category: category,
      );
      
      // Filter activities that fit in the time slot
      final duration = endTime.difference(startTime);
      return activities.where((activity) {
        final requiredDuration = Duration(minutes: (activity.typicalDurationHours * 60).round());
        return requiredDuration <= duration;
      }).toList();
    } catch (e) {
      Logger.error('Failed to get activity suggestions: $e');
      return [];
    }
  }
}