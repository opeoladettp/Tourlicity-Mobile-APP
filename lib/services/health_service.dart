import 'api_service.dart';
import '../utils/logger.dart';

class HealthService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getBasicHealth() async {
    try {
      final response = await _apiService.get('/health');
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Health check failed');
    } catch (e) {
      Logger.warning('⚠️ Health check failed: $e');
      return {
        'status': 'OFFLINE',
        'timestamp': DateTime.now().toIso8601String(),
        'services': {
          'database': 'disconnected',
          'redis': 'disconnected',
        },
      };
    }
  }

  Future<Map<String, dynamic>> getDetailedHealth() async {
    try {
      final response = await _apiService.get('/health/detailed');
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Detailed health check failed');
    } catch (e) {
      Logger.warning('⚠️ Detailed health check failed: $e');
      return {
        'status': 'OFFLINE',
        'timestamp': DateTime.now().toIso8601String(),
        'services': {
          'database': {'status': 'disconnected'},
          'redis': {'status': 'disconnected'},
        },
        'performance': {
          'totalResponseTime': 'N/A',
          'memory': {'heapUsed': 'N/A'},
        },
      };
    }
  }

  Future<bool> isBackendHealthy() async {
    try {
      final health = await getBasicHealth();
      return health['status'] == 'OK';
    } catch (e) {
      return false;
    }
  }
}