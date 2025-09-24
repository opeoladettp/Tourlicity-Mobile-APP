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
      Logger.info('🔍 Fetching active tour templates from /tour-templates/active');
      final response = await _apiService.get('/tour-templates/active');
      
      Logger.info('📡 Response status: ${response.statusCode}');
      Logger.info('📋 Response data type: ${response.data.runtimeType}');
      
      if (response.statusCode == 200) {
        dynamic responseData = response.data;
        Logger.info('📄 Raw response data: $responseData');
        
        if (responseData is Map<String, dynamic>) {
          Logger.info('📦 Response is Map, checking for data/templates keys');
          if (responseData.containsKey('data') && responseData['data'] is List) {
            responseData = responseData['data'];
            Logger.info('✅ Found data key with ${responseData.length} items');
          } else if (responseData.containsKey('templates') && responseData['templates'] is List) {
            responseData = responseData['templates'];
            Logger.info('✅ Found templates key with ${responseData.length} items');
          } else {
            Logger.warning('⚠️ No data or templates key found in response');
            return [];
          }
        }
        
        if (responseData is List) {
          Logger.info('📋 Processing ${responseData.length} tour templates');
          final templates = <TourTemplate>[];
          
          for (var json in responseData) {
            try {
              final template = TourTemplate.fromJson(json);
              templates.add(template);
            } catch (e) {
              Logger.error('❌ Failed to parse tour template: $e');
              Logger.error('📄 Problematic JSON: $json');
              // Skip this template and continue with others
              continue;
            }
          }
          
          Logger.info('✅ Successfully parsed ${templates.length} tour templates');
          return templates;
        }
        
        Logger.warning('⚠️ Response data is not a List');
        return [];
      }
      throw Exception('Failed to load active tour templates - Status: ${response.statusCode}');
    } catch (e) {
      Logger.error('❌ Failed to load active tour templates: $e');
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
  Future<TourTemplate> createTourTemplate(Map<String, dynamic> templateData) async {
    try {
      final response = await _apiService.post('/tour-templates', data: templateData);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return TourTemplate.fromJson(response.data['template'] ?? response.data);
      }
      throw Exception('Failed to create tour template');
    } catch (e) {
      Logger.error('Failed to create tour template: $e');
      rethrow;
    }
  }

  /// Update tour template (System Admin only)
  Future<TourTemplate> updateTourTemplate(String id, Map<String, dynamic> templateData) async {
    try {
      final response = await _apiService.put('/tour-templates/$id', data: templateData);
      
      if (response.statusCode == 200) {
        return TourTemplate.fromJson(response.data['template'] ?? response.data);
      }
      throw Exception('Failed to update tour template');
    } catch (e) {
      Logger.error('Failed to update tour template: $e');
      rethrow;
    }
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