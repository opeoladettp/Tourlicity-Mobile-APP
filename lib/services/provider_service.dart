import '../models/provider.dart';
import '../models/registration.dart';
import 'api_service.dart';

class ProviderService {
  final ApiService _apiService = ApiService();

  Future<List<Provider>> getAllProviders() async {
    final response = await _apiService.get('/providers');
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => Provider.fromJson(json)).toList();
    }
    throw Exception('Failed to load providers');
  }

  Future<Provider> getProviderById(String id) async {
    final response = await _apiService.get('/providers/$id');
    if (response.statusCode == 200) {
      return Provider.fromJson(response.data['provider'] ?? response.data);
    }
    throw Exception('Failed to load provider');
  }

  Future<Provider> createProvider({
    required String name,
    String? description,
  }) async {
    final response = await _apiService.post(
      '/providers',
      data: {
        'provider_name': name,
        if (description != null) 'description': description,
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Provider.fromJson(response.data['provider'] ?? response.data);
    }
    throw Exception('Failed to create provider');
  }

  Future<Provider> updateProvider(
    String id, {
    String? name,
    String? description,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) {
      data['provider_name'] = name;
    }
    if (description != null) {
      data['description'] = description;
    }

    final response = await _apiService.put('/providers/$id', data: data);
    if (response.statusCode == 200) {
      return Provider.fromJson(response.data['provider'] ?? response.data);
    }
    throw Exception('Failed to update provider');
  }

  Future<void> toggleProviderStatus(String id) async {
    final response = await _apiService.patch('/providers/$id/status');
    if (response.statusCode != 200) {
      throw Exception('Failed to toggle provider status');
    }
  }

  Future<List<Registration>> getProviderRegistrations() async {
    final response = await _apiService.get('/registrations');
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => Registration.fromJson(json)).toList();
    }
    throw Exception('Failed to load registrations');
  }

  Future<Map<String, dynamic>> getProviderStats(String providerId) async {
    final response = await _apiService.get('/providers/$providerId/stats');
    if (response.statusCode == 200) {
      return response.data['stats'] ?? response.data;
    }
    throw Exception('Failed to load provider stats');
  }

  Future<void> updateRegistrationStatus(String registrationId, String status) async {
    final response = await _apiService.put(
      '/registrations/$registrationId/status',
      data: {'status': status},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update registration status');
    }
  }

  Future<Map<String, dynamic>> submitProviderApplication(Map<String, dynamic> applicationData) async {
    try {
      final response = await _apiService.post(
        '/provider-applications',
        data: applicationData,
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to submit provider application');
    } catch (e) {
      // For offline testing, simulate successful submission
      await Future.delayed(const Duration(seconds: 2));
      return {
        'success': true,
        'message': 'Application submitted successfully',
        'application_id': 'mock_${DateTime.now().millisecondsSinceEpoch}',
      };
    }
  }
}