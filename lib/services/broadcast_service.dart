import '../models/broadcast.dart';
import '../utils/logger.dart';
import 'api_service.dart';

class BroadcastService {
  final ApiService _apiService = ApiService();

  /// Get all broadcasts (Admin/Provider only)
  Future<List<Broadcast>> getAllBroadcasts({
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
        if (providerId != null && providerId.isNotEmpty)
          'provider_id': providerId,
      };

      final response = await _apiService.get(
        '/broadcasts',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data['broadcasts'] ?? [];
        return data.map<Broadcast>((json) => Broadcast.fromJson(json)).toList();
      }
      throw Exception('Failed to get broadcasts');
    } catch (e) {
      Logger.error('Failed to get broadcasts: $e');
      rethrow;
    }
  }

  /// Get broadcasts for a specific tour (All users with access)
  Future<List<Broadcast>> getBroadcastsForTour(
    String tourId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      final response = await _apiService.get(
        '/broadcasts/tour/$tourId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data['broadcasts'] ?? [];
        return data.map<Broadcast>((json) => Broadcast.fromJson(json)).toList();
      }
      throw Exception('Failed to get tour broadcasts');
    } catch (e) {
      Logger.error('Failed to get tour broadcasts: $e');
      rethrow;
    }
  }

  /// Get broadcast by ID (Admin/Provider only)
  Future<Broadcast> getBroadcastById(String broadcastId) async {
    try {
      final response = await _apiService.get('/broadcasts/$broadcastId');

      if (response.statusCode == 200) {
        return Broadcast.fromJson(response.data['broadcast'] ?? response.data);
      }
      throw Exception('Failed to get broadcast');
    } catch (e) {
      Logger.error('Failed to get broadcast by ID: $e');
      rethrow;
    }
  }

  /// Create new broadcast (Admin/Provider only)
  Future<Broadcast> createBroadcast({
    required String customTourId,
    required String message,
    String status = 'draft',
    Map<String, dynamic>? data,
  }) async {
    try {
      final requestData = {
        'custom_tour_id': customTourId,
        'message': message,
        'status': status,
        if (data != null) 'data': data,
      };

      final response = await _apiService.post('/broadcasts', data: requestData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Broadcast.fromJson(response.data['broadcast'] ?? response.data);
      }
      throw Exception('Failed to create broadcast');
    } catch (e) {
      Logger.error('Failed to create broadcast: $e');
      rethrow;
    }
  }

  /// Update broadcast (Admin/Provider only)
  Future<Broadcast> updateBroadcast({
    required String broadcastId,
    String? message,
    String? status,
    Map<String, dynamic>? data,
  }) async {
    try {
      final requestData = <String, dynamic>{};
      if (message != null) requestData['message'] = message;
      if (status != null) requestData['status'] = status;
      if (data != null) requestData['data'] = data;

      final response = await _apiService.put(
        '/broadcasts/$broadcastId',
        data: requestData,
      );

      if (response.statusCode == 200) {
        return Broadcast.fromJson(response.data['broadcast'] ?? response.data);
      }
      throw Exception('Failed to update broadcast');
    } catch (e) {
      Logger.error('Failed to update broadcast: $e');
      rethrow;
    }
  }

  /// Publish broadcast and send notifications (Admin/Provider only)
  Future<Broadcast> publishBroadcast(String broadcastId) async {
    try {
      Logger.info(
        '🚀 Publishing broadcast and triggering notifications: $broadcastId',
      );

      final response = await _apiService.patch(
        '/broadcasts/$broadcastId/publish',
      );

      if (response.statusCode == 200) {
        Logger.info(
          '✅ Broadcast published successfully - notifications sent automatically',
        );
        return Broadcast.fromJson(response.data['broadcast'] ?? response.data);
      }
      throw Exception('Failed to publish broadcast');
    } catch (e) {
      Logger.error('Failed to publish broadcast: $e');
      rethrow;
    }
  }

  /// Delete broadcast (Admin/Provider only)
  Future<void> deleteBroadcast(String broadcastId) async {
    try {
      final response = await _apiService.delete('/broadcasts/$broadcastId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete broadcast');
      }
    } catch (e) {
      Logger.error('Failed to delete broadcast: $e');
      rethrow;
    }
  }

  /// Create and immediately publish broadcast with notifications
  Future<Broadcast> createAndPublishBroadcast({
    required String customTourId,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      Logger.info(
        '🚀 Creating and publishing broadcast with automatic notifications',
      );

      // Create broadcast with published status to trigger notifications immediately
      final broadcast = await createBroadcast(
        customTourId: customTourId,
        message: message,
        status: 'published',
        data: data,
      );

      Logger.info(
        '✅ Broadcast created and published - notifications sent automatically',
      );
      return broadcast;
    } catch (e) {
      Logger.error('Failed to create and publish broadcast: $e');
      rethrow;
    }
  }

  /// Send welcome message to tour participants
  Future<Broadcast> sendWelcomeMessage({
    required String customTourId,
    required String tourName,
    required String providerName,
    String? customMessage,
  }) async {
    try {
      final message =
          customMessage ??
          'Welcome to $tourName! 🎉\n\n'
              'We\'re excited to have you join us on this amazing adventure. '
              'You\'ll receive updates and important information through this channel.\n\n'
              'If you have any questions, feel free to reach out to us.\n\n'
              'Best regards,\n$providerName';

      return await createAndPublishBroadcast(
        customTourId: customTourId,
        message: message,
        data: {
          'type': 'welcome',
          'tour_name': tourName,
          'provider_name': providerName,
        },
      );
    } catch (e) {
      Logger.error('Failed to send welcome message: $e');
      rethrow;
    }
  }

  /// Send tour update message
  Future<Broadcast> sendTourUpdate({
    required String customTourId,
    required String updateMessage,
    required String tourName,
    String? urgencyLevel = 'normal',
  }) async {
    try {
      final message = 'Tour Update - $tourName\n\n$updateMessage';

      return await createAndPublishBroadcast(
        customTourId: customTourId,
        message: message,
        data: {
          'type': 'tour_update',
          'tour_name': tourName,
          'urgency_level': urgencyLevel,
        },
      );
    } catch (e) {
      Logger.error('Failed to send tour update: $e');
      rethrow;
    }
  }

  /// Send emergency notification
  Future<Broadcast> sendEmergencyNotification({
    required String customTourId,
    required String emergencyMessage,
    required String tourName,
    required String contactInfo,
  }) async {
    try {
      final message =
          '🚨 URGENT - $tourName\n\n'
          '$emergencyMessage\n\n'
          'Contact Information: $contactInfo\n\n'
          'Please respond if you receive this message.';

      return await createAndPublishBroadcast(
        customTourId: customTourId,
        message: message,
        data: {
          'type': 'emergency',
          'tour_name': tourName,
          'contact_info': contactInfo,
          'urgency_level': 'high',
        },
      );
    } catch (e) {
      Logger.error('Failed to send emergency notification: $e');
      rethrow;
    }
  }

  /// Send meeting point update
  Future<Broadcast> sendMeetingPointUpdate({
    required String customTourId,
    required String newMeetingPoint,
    required String tourName,
    required DateTime meetingTime,
  }) async {
    try {
      final timeStr =
          '${meetingTime.hour.toString().padLeft(2, '0')}:${meetingTime.minute.toString().padLeft(2, '0')}';

      final message =
          'Meeting Point Update - $tourName\n\n'
          '📍 New Meeting Point: $newMeetingPoint\n'
          '🕐 Time: $timeStr\n\n'
          'Please make note of this change and arrive on time.';

      return await createAndPublishBroadcast(
        customTourId: customTourId,
        message: message,
        data: {
          'type': 'meeting_point_update',
          'tour_name': tourName,
          'meeting_point': newMeetingPoint,
          'meeting_time': meetingTime.toIso8601String(),
        },
      );
    } catch (e) {
      Logger.error('Failed to send meeting point update: $e');
      rethrow;
    }
  }

  /// Send itinerary change notification
  Future<Broadcast> sendItineraryChange({
    required String customTourId,
    required String changeDescription,
    required String tourName,
    String? reason,
  }) async {
    try {
      final message =
          'Itinerary Update - $tourName\n\n'
          '📋 Changes: $changeDescription\n'
          '${reason != null ? '\n💡 Reason: $reason\n' : ''}'
          '\nWe apologize for any inconvenience and look forward to an amazing experience together!';

      return await createAndPublishBroadcast(
        customTourId: customTourId,
        message: message,
        data: {
          'type': 'itinerary_change',
          'tour_name': tourName,
          'change_description': changeDescription,
          if (reason != null) 'reason': reason,
        },
      );
    } catch (e) {
      Logger.error('Failed to send itinerary change: $e');
      rethrow;
    }
  }

  /// Send reminder message
  Future<Broadcast> sendReminder({
    required String customTourId,
    required String reminderMessage,
    required String tourName,
    String reminderType = 'general',
  }) async {
    try {
      final message =
          'Reminder - $tourName\n\n'
          '⏰ $reminderMessage';

      return await createAndPublishBroadcast(
        customTourId: customTourId,
        message: message,
        data: {
          'type': 'reminder',
          'tour_name': tourName,
          'reminder_type': reminderType,
        },
      );
    } catch (e) {
      Logger.error('Failed to send reminder: $e');
      rethrow;
    }
  }
}
