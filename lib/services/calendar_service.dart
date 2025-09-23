import '../models/calendar_entry.dart';
import 'api_service.dart';
import '../utils/logger.dart';

class CalendarService {
  final ApiService _apiService = ApiService();

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

  Future<List<CalendarEntry>> getDefaultActivities() async {
    try {
      final response = await _apiService.get('/calendar/default-activities');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => CalendarEntry.fromJson(json)).toList();
      }
      throw Exception('Failed to load default activities');
    } catch (e) {
      Logger.warning('⚠️ API call failed, returning empty activities list: $e');
      return [];
    }
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
}