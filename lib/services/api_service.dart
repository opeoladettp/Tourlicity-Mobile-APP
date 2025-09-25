import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../utils/logger.dart';

class ApiService {
  late final Dio _dio;
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: '${AppConfig.apiBaseUrl}/api',
      connectTimeout: AppConfig.apiTimeout,
      receiveTimeout: AppConfig.apiTimeout,
      sendTimeout: AppConfig.apiTimeout,
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          Logger.debug('🔑 API Request with token: ${token.substring(0, 20)}...');
        } else {
          Logger.warning('⚠️ API Request without token');
        }
        Logger.debug('📡 ${options.method} ${options.path}');
        if (options.data != null) {
          Logger.debug('📤 Request data: ${options.data}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        Logger.debug('📥 API Response: ${response.statusCode} ${response.requestOptions.path}');
        Logger.debug('📋 Response data: ${response.data}');
        handler.next(response);
      },
      onError: (error, handler) {
        Logger.error('🚨 API Error: ${error.response?.statusCode} ${error.message}');
        
        if (error.response?.statusCode == 401) {
          Logger.warning('🔒 Token expired, clearing access token');
          clearAccessToken();
        }
        
        if (error.response?.statusCode == 400) {
          Logger.error('❌ Bad Request (400): ${error.response?.data}');
        }
        
        // Log network errors for debugging
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.connectionError) {
          Logger.warning('🌐 Network error (offline mode): ${error.message}');
        }
        
        handler.next(error);
      },
    ));
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.accessTokenKey);
  }

  Future<void> setAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.accessTokenKey, token);
  }

  Future<void> clearAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.accessTokenKey);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }

  Future<Response> patch(String path, {dynamic data}) {
    return _dio.patch(path, data: data);
  }
}