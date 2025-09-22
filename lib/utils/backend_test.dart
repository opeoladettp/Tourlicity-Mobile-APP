import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'logger.dart';

class BackendTest {
  static Future<Map<String, dynamic>> testConnection() async {
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    final results = <String, dynamic>{
      'backend_url': AppConfig.apiBaseUrl,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      // Test health endpoint
      final healthResponse = await dio.get('/health');
      results['health_check'] = {
        'status': 'success',
        'status_code': healthResponse.statusCode,
        'data': healthResponse.data,
      };
    } catch (e) {
      results['health_check'] = {
        'status': 'failed',
        'error': e.toString(),
      };
    }

    try {
      // Test API base endpoint
      final apiResponse = await dio.get('/api');
      results['api_check'] = {
        'status': 'success',
        'status_code': apiResponse.statusCode,
        'data': apiResponse.data,
      };
    } catch (e) {
      results['api_check'] = {
        'status': 'failed',
        'error': e.toString(),
      };
    }

    return results;
  }

  static void printTestResults(Map<String, dynamic> results) {
    Logger.test('=== Backend Connection Test ===');
    Logger.test('Backend URL: ${results['backend_url']}');
    Logger.test('Test Time: ${results['timestamp']}');
    Logger.test('');
    
    Logger.test('Health Check:');
    final healthCheck = results['health_check'];
    Logger.test('  Status: ${healthCheck['status']}');
    if (healthCheck['status'] == 'success') {
      Logger.test('  Status Code: ${healthCheck['status_code']}');
      Logger.test('  Response: ${healthCheck['data']}');
    } else {
      Logger.test('  Error: ${healthCheck['error']}');
    }
    Logger.test('');
    
    Logger.test('API Check:');
    final apiCheck = results['api_check'];
    Logger.test('  Status: ${apiCheck['status']}');
    if (apiCheck['status'] == 'success') {
      Logger.test('  Status Code: ${apiCheck['status_code']}');
      Logger.test('  Response: ${apiCheck['data']}');
    } else {
      Logger.test('  Error: ${apiCheck['error']}');
    }
    Logger.test('===============================');
  }
}