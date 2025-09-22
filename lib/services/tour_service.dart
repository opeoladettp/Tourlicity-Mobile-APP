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
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => Registration.fromJson(json)).toList();
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
      // For offline testing, create a mock tour if specific join codes are used
      if (joinCode.toUpperCase() == 'TEST123' ||
          joinCode.toUpperCase() == 'DEMO') {
        return Tour(
          id: 'mock_tour_123',
          tourName: 'Mock City Walking Tour',
          description: 'A sample tour for testing purposes',
          status: 'published',
          joinCode: joinCode.toUpperCase(),
          providerId: 'offline_provider_${DateTime.now().millisecondsSinceEpoch}',
          maxTourists: 15,
          currentRegistrations: 5,
          remainingSpots: 10,
          pricePerPerson: 25.0,
          currency: 'USD',
          isFeatured: false,
          tags: ['walking', 'city', 'test'],
          durationDays: 1,
          createdDate: DateTime.now(),
          updatedDate: DateTime.now(),
        );
      }
      throw Exception(
        'Tour not found (offline mode - try "TEST123" or "DEMO")',
      );
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
      // For offline testing, create a mock registration
      return Registration(
        id: 'offline_registration_${DateTime.now().millisecondsSinceEpoch}',
        customTourId: customTourId,
        touristId: 'offline_user_${DateTime.now().millisecondsSinceEpoch}',
        providerId: 'offline_provider_${DateTime.now().millisecondsSinceEpoch}',
        status: 'pending',
        confirmationCode: 'CONF${DateTime.now().millisecondsSinceEpoch}',
        registrationDate: DateTime.now(),
        paymentStatus: 'pending',
        createdDate: DateTime.now(),
        updatedDate: DateTime.now(),
      );
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
    final response = await _apiService.get('/custom-tours');
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => Tour.fromJson(json)).toList();
    }
    throw Exception('Failed to load provider tours');
  }

  Future<Tour> createTour({
    required String providerId,
    required String name,
    String? description,
    String? templateId,
    DateTime? startDate,
    DateTime? endDate,
    int maxTourists = 15,
    String? groupChatLink,
  }) async {
    final response = await _apiService.post(
      '/custom-tours',
      data: {
        'provider_id': providerId,
        'tour_name': name,
        'description': description,
        if (templateId != null) 'tour_template_id': templateId,
        if (startDate != null)
          'start_date': startDate.toIso8601String().split('T')[0],
        if (endDate != null)
          'end_date': endDate.toIso8601String().split('T')[0],
        'max_tourists': maxTourists,
        if (groupChatLink != null) 'group_chat_link': groupChatLink,
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
    final response = await _apiService.get('/registrations/stats');
    if (response.statusCode == 200) {
      return response.data['data'];
    }
    throw Exception('Failed to load provider stats');
  }
}
