import '../models/provider.dart';
import '../models/registration.dart';
import 'api_service.dart';

class ProviderService {
  final ApiService _apiService = ApiService();

  Future<List<Provider>> getAllProviders() async {
    final response = await _apiService.get('/providers');
    if (response.statusCode == 200) {
      // Handle both List and Map responses
      dynamic responseData = response.data;

      // If response is a Map, try to extract the data array
      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('data') && responseData['data'] is List) {
          responseData = responseData['data'];
        } else if (responseData.containsKey('providers') &&
            responseData['providers'] is List) {
          responseData = responseData['providers'];
        } else {
          // If it's a Map but not containing a list, return empty list
          return [];
        }
      }

      // If response is a List, process it
      if (responseData is List) {
        return responseData.map((json) => Provider.fromJson(json)).toList();
      }

      // If we get here, return empty list
      return [];
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
      // Handle both List and Map responses
      dynamic responseData = response.data;

      // If response is a Map, try to extract the data array
      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('data') && responseData['data'] is List) {
          responseData = responseData['data'];
        } else if (responseData.containsKey('registrations') &&
            responseData['registrations'] is List) {
          responseData = responseData['registrations'];
        } else {
          // If it's a Map but not containing a list, return empty list
          return [];
        }
      }

      // If response is a List, process it
      if (responseData is List) {
        return responseData.map((json) => Registration.fromJson(json)).toList();
      }

      // If we get here, return empty list
      return [];
    }
    throw Exception('Failed to load registrations');
  }

  Future<List<dynamic>> getProviderAdmins(String providerId) async {
    final response = await _apiService.get('/providers/$providerId/admins');
    if (response.statusCode == 200) {
      return response.data['admins'] ?? response.data;
    }
    throw Exception('Failed to load provider admins');
  }

  Future<Map<String, dynamic>> getProviderStats(String providerId) async {
    final response = await _apiService.get('/providers/$providerId/stats');
    if (response.statusCode == 200) {
      return response.data['stats'] ?? response.data;
    }
    throw Exception('Failed to load provider stats');
  }

  Future<Map<String, dynamic>> getRegistrationStats() async {
    final response = await _apiService.get('/registrations/stats');
    if (response.statusCode == 200) {
      return response.data['stats'] ?? response.data;
    }
    throw Exception('Failed to load registration stats');
  }

  Future<void> updateRegistrationStatus(
    String registrationId,
    String status,
  ) async {
    final response = await _apiService.put(
      '/registrations/$registrationId/status',
      data: {'status': status},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update registration status');
    }
  }

  Future<Provider> toggleProviderStatusById(String id, bool isActive) async {
    final response = await _apiService.patch(
      '/providers/$id/status',
      data: {'is_active': isActive},
    );
    if (response.statusCode == 200) {
      return Provider.fromJson(response.data['provider'] ?? response.data);
    }
    throw Exception('Failed to toggle provider status');
  }

  // Note: Provider applications are now handled through the RoleChangeService
  // using the /role-change-requests endpoint
}
