import 'api_service.dart';
import '../utils/logger.dart';

class DashboardService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getUserDashboard() async {
    try {
      final response = await _apiService.get('/users/dashboard');
      if (response.statusCode == 200) {
        return response.data['dashboard'] ?? response.data;
      }
      throw Exception('Failed to load dashboard data');
    } catch (e) {
      Logger.warning('⚠️ Dashboard API call failed: $e');
      // Return empty data instead of mock data
      return {
        'total_tours': 0,
        'active_registrations': 0,
        'completed_tours': 0,
        'upcoming_tours': [],
        'recent_activity': [],
      };
    }
  }

  Future<Map<String, dynamic>> getRegistrationStats() async {
    try {
      final response = await _apiService.get('/registrations/stats');
      if (response.statusCode == 200) {
        return response.data['stats'] ?? response.data;
      }
      throw Exception('Failed to load registration stats');
    } catch (e) {
      Logger.warning('⚠️ Registration stats API call failed: $e');
      return {
        'total_registrations': 0,
        'pending_registrations': 0,
        'confirmed_registrations': 0,
        'cancelled_registrations': 0,
      };
    }
  }
}