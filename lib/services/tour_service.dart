import 'package:dio/dio.dart';
import '../models/tour.dart';
import '../models/registration.dart';
import 'api_service.dart';
import '../utils/logger.dart';

class TourService {
  final ApiService _apiService = ApiService();

  // Tourist functions
  Future<List<Registration>> getMyRegistrations() async {
    try {
      final response = await _apiService.get('/registrations/my');
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        // Handle different response structures
        if (responseData is Map<String, dynamic>) {
          // Try to get data from 'data' key first, then 'registrations', then direct response
          final registrationsData = responseData['data'] ?? responseData['registrations'] ?? responseData;
          
          if (registrationsData is List) {
            return registrationsData.map((json) => Registration.fromJson(json)).toList();
          } else if (registrationsData is Map<String, dynamic> && registrationsData.containsKey('registrations')) {
            // Handle nested registrations
            final regList = registrationsData['registrations'];
            if (regList is List) {
              return regList.map((json) => Registration.fromJson(json)).toList();
            }
          }
        } else if (responseData is List) {
          // Handle direct list response
          return responseData.map((json) => Registration.fromJson(json)).toList();
        }
        
        Logger.warning('⚠️ Unexpected registrations response structure, returning empty list');
        return [];
      }
      throw Exception('Failed to load registrations');
    } catch (e) {
      Logger.warning(
        '⚠️ API call failed, returning empty registrations list: $e',
      );
      return [];
    }
  }

  Future<List<Tour>> getMyTours() async {
    try {
      final registrations = await getMyRegistrations();
      final List<Tour> tours = [];

      for (var registration in registrations) {
        try {
          final tourResponse = await _apiService.get(
            '/custom-tours/${registration.customTourId}',
          );
          if (tourResponse.statusCode == 200) {
            tours.add(
              Tour.fromJson(tourResponse.data['tour'] ?? tourResponse.data),
            );
          }
        } catch (e) {
          Logger.warning(
            'Failed to load tour details for ${registration.customTourId}: $e',
          );
        }
      }
      return tours;
    } catch (e) {
      Logger.warning('⚠️ API call failed, returning empty tours list: $e');
      return [];
    }
  }

  Future<Tour> searchTourByJoinCode(String joinCode) async {
    try {
      final response = await _apiService.get('/custom-tours/search/$joinCode');
      if (response.statusCode == 200) {
        return Tour.fromJson(response.data['tour'] ?? response.data);
      }
      throw Exception('Tour not found');
    } catch (e) {
      Logger.warning('⚠️ API call failed for tour search: $e');
      throw Exception('Tour not found');
    }
  }

  Future<Registration> registerForTour(
    String customTourId, {
    String? notes,
  }) async {
    try {
      final response = await _apiService.post(
        '/registrations',
        data: {
          'custom_tour_id': customTourId,
          if (notes != null) 'notes': notes,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Registration.fromJson(
          response.data['registration'] ?? response.data,
        );
      }
      throw Exception('Failed to register for tour');
    } catch (e) {
      Logger.warning('⚠️ API call failed for tour registration: $e');
      rethrow;
    }
  }

  Future<void> unregisterFromTour(String registrationId) async {
    final response = await _apiService.delete('/registrations/$registrationId');
    if (response.statusCode != 200) {
      throw Exception('Failed to unregister from tour');
    }
  }

  // Provider Admin functions
  Future<List<Tour>> getProviderTours() async {
    try {
      final response = await _apiService.get('/custom-tours');
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData is Map<String, dynamic>) {
          // Try to get data from 'data' key first, then fallback to direct response
          final toursData = responseData.containsKey('data') ? responseData['data'] : responseData;
          
          if (toursData is List) {
            return toursData.map((json) => Tour.fromJson(json)).toList();
          } else if (toursData is Map<String, dynamic> && toursData.containsKey('tours')) {
            // Handle case where tours are nested under 'tours' key
            final toursList = toursData['tours'];
            if (toursList is List) {
              return toursList.map((json) => Tour.fromJson(json)).toList();
            }
          }
        } else if (responseData is List) {
          // Handle direct list response
          return responseData.map((json) => Tour.fromJson(json)).toList();
        }
        
        Logger.warning('⚠️ Unexpected tours response structure, returning empty list');
        return [];
      }
      throw Exception('Failed to load provider tours: ${response.statusCode}');
    } catch (e) {
      Logger.error('❌ Error loading provider tours: $e');
      // Return empty list instead of throwing to prevent UI crashes
      return [];
    }
  }

  Future<Tour> createTour({
    required String providerId,
    required String tourName,
    String? description, // Keep parameter for backward compatibility but don't send to API
    String? tourTemplateId,
    DateTime? startDate,
    DateTime? endDate,
    int maxTourists = 15,
    String? groupChatLink,
    String? featuresImage,
    List<String>? teaserImages,
  }) async {
    final response = await _apiService.post(
      '/custom-tours',
      data: {
        'provider_id': providerId,
        'tour_name': tourName,
        if (tourTemplateId != null) 'tour_template_id': tourTemplateId,
        if (startDate != null)
          'start_date': startDate.toIso8601String().split('T')[0],
        if (endDate != null)
          'end_date': endDate.toIso8601String().split('T')[0],
        'max_tourists': maxTourists,
        if (groupChatLink != null) 'group_chat_link': groupChatLink,
        if (featuresImage != null) 'features_image': featuresImage,
        if (teaserImages != null) 'teaser_images': teaserImages,
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Tour.fromJson(response.data['tour'] ?? response.data);
    }
    throw Exception('Failed to create tour');
  }

  Future<Tour> updateTour(
    String tourId, {
    String? name,
    String? description,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) {
      data['tour_name'] = name;
    }
    if (description != null) {
      data['description'] = description;
    }
    if (startDate != null) {
      data['start_date'] = startDate.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      data['end_date'] = endDate.toIso8601String().split('T')[0];
    }

    Response response;
    if (status != null) {
      // Use PATCH for status updates
      response = await _apiService.patch(
        '/custom-tours/$tourId/status',
        data: {'status': status},
      );
    } else {
      // Use PUT for other updates
      response = await _apiService.put('/custom-tours/$tourId', data: data);
    }

    if (response.statusCode == 200) {
      return Tour.fromJson(response.data['tour'] ?? response.data);
    }
    throw Exception('Failed to update tour');
  }

  Future<void> deleteTour(String tourId) async {
    final response = await _apiService.delete('/custom-tours/$tourId');
    if (response.statusCode != 200) {
      throw Exception('Failed to delete tour');
    }
  }

  Future<Map<String, dynamic>> getProviderStats() async {
    try {
      final response = await _apiService.get('/registrations/stats');
      if (response.statusCode == 200) {
        final data = response.data;
        
        // Handle different response structures
        if (data is Map<String, dynamic>) {
          // If response has 'data' key, use it; otherwise use the response directly
          final statsData = data.containsKey('data') ? data['data'] : data;
          
          if (statsData != null && statsData is Map<String, dynamic>) {
            return statsData;
          }
        }
        
        // Return empty stats if data structure is unexpected
        Logger.warning('⚠️ Unexpected stats response structure, returning empty stats');
        return {};
      }
      throw Exception('Failed to load provider stats: ${response.statusCode}');
    } catch (e) {
      Logger.error('❌ Error loading provider stats: $e');
      // Return empty stats instead of throwing to prevent UI crashes
      return {};
    }
  }
}
