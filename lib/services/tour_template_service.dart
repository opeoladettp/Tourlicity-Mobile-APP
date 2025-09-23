import '../models/tour_template.dart';
import '../utils/logger.dart';
import 'api_service.dart';

class TourTemplateService {
  final ApiService _apiService = ApiService();

  /// Get all tour templates (System Admin, Provider Admin)
  Future<List<TourTemplate>> getAllTourTemplates({
    int page = 1,
    int limit = 10,
    String? search,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (isActive != null) 'is_active': isActive,
      };

      final response = await _apiService.get('/tour-templates', queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        dynamic responseData = response.data;
        
        // Handle both List and Map responses
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data') && responseData['data'] is List) {
            responseData = responseData['data'];
          } else if (responseData.containsKey('templates') && responseData['templates'] is List) {
            responseData = responseData['templates'];
          } else {
            return [];
          }
        }
        
        if (responseData is List) {
          return responseData.map((json) => TourTemplate.fromJson(json)).toList();
        }
        
        return [];
      }
      throw Exception('Failed to load tour templates');
    } catch (e) {
      Logger.error('Failed to load tour templates: $e');
      return [];
    }
  }

  /// Get active tour templates
  Future<List<TourTemplate>> getActiveTourTemplates() async {
    try {
      final response = await _apiService.get('/tour-templates/active');
      
      if (response.statusCode == 200) {
        dynamic responseData = response.data;
        
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data') && responseData['data'] is List) {
            responseData = responseData['data'];
          } else if (responseData.containsKey('templates') && responseData['templates'] is List) {
            responseData = responseData['templates'];
          } else {
            return [];
          }
        }
        
        if (responseData is List) {
          return responseData.map((json) => TourTemplate.fromJson(json)).toList();
        }
        
        return [];
      }
      throw Exception('Failed to load active tour templates');
    } catch (e) {
      Logger.error('Failed to load active tour templates: $e');
      return [];
    }
  }

  /// Get tour template by ID
  Future<TourTemplate> getTourTemplateById(String id) async {
    final response = await _apiService.get('/tour-templates/$id');
    
    if (response.statusCode == 200) {
      return TourTemplate.fromJson(response.data['template'] ?? response.data);
    }
    throw Exception('Failed to load tour template');
  }

  /// Create new tour template (System Admin only)
  Future<TourTemplate> createTourTemplate({
    required String templateName,
    required DateTime startDate,
    required DateTime endDate,
    required String description,
    String? featuresImage,
    List<String>? teaserImages,
    List<WebLink>? webLinks,
  }) async {
    final requestData = {
      'template_name': templateName,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'description': description,
      if (featuresImage != null) 'features_image': featuresImage,
      if (teaserImages != null) 'teaser_images': teaserImages,
      if (webLinks != null) 'web_links': webLinks.map((link) => link.toJson()).toList(),
    };

    final response = await _apiService.post('/tour-templates', data: requestData);
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      return TourTemplate.fromJson(response.data['template'] ?? response.data);
    }
    throw Exception('Failed to create tour template');
  }

  /// Update tour template (System Admin only)
  Future<TourTemplate> updateTourTemplate(
    String id, {
    String? templateName,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    String? featuresImage,
    List<String>? teaserImages,
    List<WebLink>? webLinks,
  }) async {
    final requestData = <String, dynamic>{};
    
    if (templateName != null) requestData['template_name'] = templateName;
    if (startDate != null) requestData['start_date'] = startDate.toIso8601String().split('T')[0];
    if (endDate != null) requestData['end_date'] = endDate.toIso8601String().split('T')[0];
    if (description != null) requestData['description'] = description;
    if (featuresImage != null) requestData['features_image'] = featuresImage;
    if (teaserImages != null) requestData['teaser_images'] = teaserImages;
    if (webLinks != null) requestData['web_links'] = webLinks.map((link) => link.toJson()).toList();

    final response = await _apiService.put('/tour-templates/$id', data: requestData);
    
    if (response.statusCode == 200) {
      return TourTemplate.fromJson(response.data['template'] ?? response.data);
    }
    throw Exception('Failed to update tour template');
  }

  /// Toggle tour template status (System Admin only)
  Future<TourTemplate> toggleTourTemplateStatus(String id) async {
    final response = await _apiService.patch('/tour-templates/$id/status');
    
    if (response.statusCode == 200) {
      return TourTemplate.fromJson(response.data['template'] ?? response.data);
    }
    throw Exception('Failed to toggle tour template status');
  }

  /// Delete tour template (System Admin only)
  Future<void> deleteTourTemplate(String id) async {
    final response = await _apiService.delete('/tour-templates/$id');
    
    if (response.statusCode != 200) {
      throw Exception('Failed to delete tour template');
    }
  }
}