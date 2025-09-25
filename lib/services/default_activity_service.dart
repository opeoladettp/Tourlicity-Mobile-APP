import '../models/default_activity.dart';
import '../utils/logger.dart';
import 'api_service.dart';

class DefaultActivityService {
  final ApiService _apiService = ApiService();

  /// Get all default activities (System Admin, Provider Admin)
  Future<List<DefaultActivity>> getAllDefaultActivities({
    int page = 1,
    int limit = 50,
    String? search,
    String? category,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty) 'category': category,
        if (isActive != null) 'is_active': isActive,
      };

      final response = await _apiService.get('/activities', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data['activities'] ?? [];
        return data.map<DefaultActivity>((json) => DefaultActivity.fromJson(json)).toList();
      }
      throw Exception('Failed to get default activities');
    } catch (e) {
      Logger.error('Failed to get default activities: $e');
      return [];
    }
  }

  /// Get activities for selection (optimized for UI selection)
  Future<List<DefaultActivity>> getActivitiesForSelection({
    String? category,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (category != null && category.isNotEmpty) 'category': category,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final response = await _apiService.get('/activities/selection', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final data = response.data['activities'] ?? [];
        return data.map<DefaultActivity>((json) => DefaultActivity.fromJson(json)).toList();
      }
      throw Exception('Failed to get activities for selection');
    } catch (e) {
      Logger.error('Failed to get activities for selection: $e');
      return [];
    }
  }

  /// Get activity categories with counts
  Future<List<ActivityCategory>> getActivityCategories() async {
    try {
      final response = await _apiService.get('/activities/categories');

      if (response.statusCode == 200) {
        final data = response.data['categories'] ?? [];
        return data.map<ActivityCategory>((json) => ActivityCategory.fromJson(json)).toList();
      }
      throw Exception('Failed to get activity categories');
    } catch (e) {
      Logger.error('Failed to get activity categories: $e');
      return [];
    }
  }

  /// Get default activity by ID
  Future<DefaultActivity> getDefaultActivityById(String id) async {
    try {
      final response = await _apiService.get('/activities/$id');

      if (response.statusCode == 200) {
        return DefaultActivity.fromJson(response.data['activity'] ?? response.data);
      }
      throw Exception('Failed to get default activity');
    } catch (e) {
      Logger.error('Failed to get default activity by ID: $e');
      rethrow;
    }
  }

  /// Create new default activity (System Admin only)
  Future<DefaultActivity> createDefaultActivity({
    required String activityName,
    required String description,
    required double typicalDurationHours,
    required String category,
    bool isActive = true,
  }) async {
    try {
      final requestData = {
        'activity_name': activityName,
        'description': description,
        'typical_duration_hours': typicalDurationHours,
        'category': category,
        'is_active': isActive,
      };

      final response = await _apiService.post('/activities', data: requestData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return DefaultActivity.fromJson(response.data['activity'] ?? response.data);
      }
      throw Exception('Failed to create default activity');
    } catch (e) {
      Logger.error('Failed to create default activity: $e');
      rethrow;
    }
  }

  /// Update default activity (System Admin only)
  Future<DefaultActivity> updateDefaultActivity({
    required String id,
    String? activityName,
    String? description,
    double? typicalDurationHours,
    String? category,
    bool? isActive,
  }) async {
    try {
      final requestData = <String, dynamic>{};
      if (activityName != null) requestData['activity_name'] = activityName;
      if (description != null) requestData['description'] = description;
      if (typicalDurationHours != null) requestData['typical_duration_hours'] = typicalDurationHours;
      if (category != null) requestData['category'] = category;
      if (isActive != null) requestData['is_active'] = isActive;

      final response = await _apiService.put('/activities/$id', data: requestData);

      if (response.statusCode == 200) {
        return DefaultActivity.fromJson(response.data['activity'] ?? response.data);
      }
      throw Exception('Failed to update default activity');
    } catch (e) {
      Logger.error('Failed to update default activity: $e');
      rethrow;
    }
  }

  /// Toggle activity status (System Admin only)
  Future<DefaultActivity> toggleActivityStatus(String id) async {
    try {
      final response = await _apiService.patch('/activities/$id/status');

      if (response.statusCode == 200) {
        return DefaultActivity.fromJson(response.data['activity'] ?? response.data);
      }
      throw Exception('Failed to toggle activity status');
    } catch (e) {
      Logger.error('Failed to toggle activity status: $e');
      rethrow;
    }
  }

  /// Delete default activity (System Admin only)
  Future<void> deleteDefaultActivity(String id) async {
    try {
      final response = await _apiService.delete('/activities/$id');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete default activity');
      }
    } catch (e) {
      Logger.error('Failed to delete default activity: $e');
      rethrow;
    }
  }

  /// Get activities by category
  Future<List<DefaultActivity>> getActivitiesByCategory(String category) async {
    return await getActivitiesForSelection(category: category);
  }

  /// Search activities
  Future<List<DefaultActivity>> searchActivities(String query) async {
    return await getActivitiesForSelection(search: query);
  }

  /// Get popular activities (most used in calendar entries)
  Future<List<DefaultActivity>> getPopularActivities({int limit = 10}) async {
    try {
      // This could be enhanced with a specific backend endpoint for popular activities
      final activities = await getActivitiesForSelection();
      
      // For now, return the first 'limit' activities
      // In a real implementation, this would be sorted by usage count
      return activities.take(limit).toList();
    } catch (e) {
      Logger.error('Failed to get popular activities: $e');
      return [];
    }
  }

  /// Get recommended activities for a tour template
  Future<List<DefaultActivity>> getRecommendedActivitiesForTour({
    String? tourTemplateId,
    String? location,
    int? durationDays,
  }) async {
    try {
      // This could be enhanced with ML-based recommendations
      // For now, return activities from common categories
      final commonCategories = ['sightseeing', 'cultural', 'dining'];
      final List<DefaultActivity> recommended = [];

      for (final category in commonCategories) {
        final activities = await getActivitiesByCategory(category);
        recommended.addAll(activities.take(3)); // Take top 3 from each category
      }

      return recommended;
    } catch (e) {
      Logger.error('Failed to get recommended activities: $e');
      return [];
    }
  }
}