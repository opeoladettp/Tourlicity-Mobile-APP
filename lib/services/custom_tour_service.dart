import '../models/custom_tour.dart';
import '../utils/logger.dart';
import 'api_service.dart';

class CustomTourService {
  final ApiService _apiService = ApiService();

  /// Get all custom tours (System Admin, Provider Admin for own)
  Future<List<CustomTour>> getAllCustomTours({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
    String? providerId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
        if (providerId != null && providerId.isNotEmpty) 'provider_id': providerId,
      };

      final response = await _apiService.get('/custom-tours', queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        dynamic responseData = response.data;
        
        // Handle both List and Map responses
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data') && responseData['data'] is List) {
            responseData = responseData['data'];
          } else if (responseData.containsKey('tours') && responseData['tours'] is List) {
            responseData = responseData['tours'];
          } else {
            return [];
          }
        }
        
        if (responseData is List) {
          return responseData.map((json) => CustomTour.fromJson(json)).toList();
        }
        
        return [];
      }
      throw Exception('Failed to load custom tours');
    } catch (e) {
      Logger.error('Failed to load custom tours: $e');
      return [];
    }
  }

  /// Search tour by join code (Tourist)
  Future<CustomTour?> searchTourByJoinCode(String joinCode) async {
    try {
      final response = await _apiService.get('/custom-tours/search/$joinCode');
      
      if (response.statusCode == 200) {
        return CustomTour.fromJson(response.data['tour'] ?? response.data);
      }
      return null;
    } catch (e) {
      Logger.error('Failed to search tour by join code: $e');
      return null;
    }
  }

  /// Get custom tour by ID
  Future<CustomTour> getCustomTourById(String id) async {
    final response = await _apiService.get('/custom-tours/$id');
    
    if (response.statusCode == 200) {
      return CustomTour.fromJson(response.data['tour'] ?? response.data);
    }
    throw Exception('Failed to load custom tour');
  }

  /// Create new custom tour (System Admin, Provider Admin)
  Future<CustomTour> createCustomTour({
    required String providerId,
    required String tourTemplateId,
    required String tourName,
    required DateTime startDate,
    required DateTime endDate,
    required int maxTourists,
    String? groupChatLink,
    String? featuresImage,
    List<String>? teaserImages,
  }) async {
    final requestData = {
      'provider_id': providerId,
      'tour_template_id': tourTemplateId,
      'tour_name': tourName,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'max_tourists': maxTourists,
      if (groupChatLink != null) 'group_chat_link': groupChatLink,
      if (featuresImage != null) 'features_image': featuresImage,
      if (teaserImages != null) 'teaser_images': teaserImages,
    };

    final response = await _apiService.post('/custom-tours', data: requestData);
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      return CustomTour.fromJson(response.data['tour'] ?? response.data);
    }
    throw Exception('Failed to create custom tour');
  }

  /// Update custom tour (System Admin, Provider Admin for own)
  Future<CustomTour> updateCustomTour(
    String id, {
    String? tourName,
    DateTime? startDate,
    DateTime? endDate,
    int? maxTourists,
    String? groupChatLink,
    String? featuresImage,
    List<String>? teaserImages,
  }) async {
    final requestData = <String, dynamic>{};
    
    if (tourName != null) requestData['tour_name'] = tourName;
    if (startDate != null) requestData['start_date'] = startDate.toIso8601String().split('T')[0];
    if (endDate != null) requestData['end_date'] = endDate.toIso8601String().split('T')[0];
    if (maxTourists != null) requestData['max_tourists'] = maxTourists;
    if (groupChatLink != null) requestData['group_chat_link'] = groupChatLink;
    if (featuresImage != null) requestData['features_image'] = featuresImage;
    if (teaserImages != null) requestData['teaser_images'] = teaserImages;

    final response = await _apiService.put('/custom-tours/$id', data: requestData);
    
    if (response.statusCode == 200) {
      return CustomTour.fromJson(response.data['tour'] ?? response.data);
    }
    throw Exception('Failed to update custom tour');
  }

  /// Update tour status (System Admin, Provider Admin for own)
  Future<CustomTour> updateTourStatus(String id, String status) async {
    final response = await _apiService.patch('/custom-tours/$id/status', data: {'status': status});
    
    if (response.statusCode == 200) {
      return CustomTour.fromJson(response.data['tour'] ?? response.data);
    }
    throw Exception('Failed to update tour status');
  }

  /// Delete custom tour (System Admin, Provider Admin for own)
  Future<void> deleteCustomTour(String id) async {
    final response = await _apiService.delete('/custom-tours/$id');
    
    if (response.statusCode != 200) {
      throw Exception('Failed to delete custom tour');
    }
  }
}