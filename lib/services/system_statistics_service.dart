import 'api_service.dart';
import '../utils/logger.dart';

class SystemStatisticsService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getSystemStatistics() async {
    try {
      // Get users count
      final usersResponse = await _apiService.get('/users');
      int totalUsers = 0;
      if (usersResponse.statusCode == 200) {
        final usersData = usersResponse.data;
        if (usersData['pagination'] != null) {
          totalUsers = usersData['pagination']['total_items'] ?? 0;
        } else if (usersData['data'] is List) {
          totalUsers = (usersData['data'] as List).length;
        }
      }

      // Get providers count
      final providersResponse = await _apiService.get('/providers');
      int activeProviders = 0;
      if (providersResponse.statusCode == 200) {
        final providersData = providersResponse.data;
        if (providersData['data'] is List) {
          final providers = providersData['data'] as List;
          activeProviders = providers.where((p) => p['is_active'] == true).length;
        }
      }

      // Get custom tours count
      final toursResponse = await _apiService.get('/custom-tours');
      int totalTours = 0;
      if (toursResponse.statusCode == 200) {
        final toursData = toursResponse.data;
        if (toursData['pagination'] != null) {
          totalTours = toursData['pagination']['total_items'] ?? 0;
        } else if (toursData['data'] is List) {
          totalTours = (toursData['data'] as List).length;
        }
      }

      // Get pending role change requests count
      final roleRequestsResponse = await _apiService.get('/role-change-requests');
      int pendingReviews = 0;
      if (roleRequestsResponse.statusCode == 200) {
        final requestsData = roleRequestsResponse.data;
        if (requestsData['data'] is List) {
          final requests = requestsData['data'] as List;
          pendingReviews = requests.where((r) => r['status'] == 'pending').length;
        }
      }

      return {
        'total_users': totalUsers,
        'active_providers': activeProviders,
        'total_tours': totalTours,
        'pending_reviews': pendingReviews,
      };
    } catch (e) {
      Logger.error('Failed to fetch system statistics: $e');
      // Return zeros instead of mock data
      return {
        'total_users': 0,
        'active_providers': 0,
        'total_tours': 0,
        'pending_reviews': 0,
      };
    }
  }
}