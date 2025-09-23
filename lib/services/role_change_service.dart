import '../models/role_change_request.dart';
import '../utils/logger.dart';
import 'api_service.dart';

class RoleChangeService {
  final ApiService _apiService = ApiService();

  /// Submit a request to become a new provider
  Future<Map<String, dynamic>> requestToBecomeNewProvider({
    required String providerName,
    required String country,
    required String address,
    required String phoneNumber,
    required String emailAddress,
    required String corporateTaxId,
    required String companyDescription,
    String? logoUrl,
    String? requestMessage,
  }) async {
    // Validate required fields
    if (providerName.trim().isEmpty) {
      throw Exception('Provider name is required');
    }
    if (country.trim().isEmpty) {
      throw Exception('Country is required');
    }
    if (address.trim().isEmpty) {
      throw Exception('Address is required');
    }
    if (phoneNumber.trim().isEmpty) {
      throw Exception('Phone number is required');
    }
    if (emailAddress.trim().isEmpty) {
      throw Exception('Email address is required');
    }
    if (corporateTaxId.trim().isEmpty) {
      throw Exception('Corporate Tax ID is required');
    }
    if (companyDescription.trim().isEmpty) {
      throw Exception('Company description is required');
    }

    try {
      final requestData = {
        'request_type': 'become_new_provider',
        'proposed_provider_data': {
          'provider_name': providerName.trim(),
          'country': country.trim(),
          'address': address.trim(),
          'phone_number': phoneNumber.trim(),
          'email_address': emailAddress.trim(),
          'corporate_tax_id': corporateTaxId.trim(),
          'company_description': companyDescription.trim(),
          if (logoUrl != null && logoUrl.trim().isNotEmpty) 'logo_url': logoUrl.trim(),
        },
        if (requestMessage != null && requestMessage.trim().isNotEmpty) 
          'request_message': requestMessage.trim(),
      };

      Logger.info('🚀 Submitting provider application with data: $requestData');

      final response = await _apiService.post(
        '/role-change-requests',
        data: requestData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        Logger.info('✅ Provider application submitted successfully');
        return response.data ?? {};
      }
      
      Logger.error('❌ Provider application failed with status: ${response.statusCode}');
      Logger.error('Response data: ${response.data}');
      
      // Try to extract error message from response
      String errorMessage = 'Failed to submit provider application';
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('message')) {
          errorMessage = data['message'];
        } else if (data.containsKey('error')) {
          errorMessage = data['error'];
        } else if (data.containsKey('detail')) {
          errorMessage = data['detail'];
        }
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      Logger.error('Failed to submit provider application: $e');
      
      // If it's a DioException, try to get more details
      if (e.toString().contains('DioException') || e.toString().contains('400')) {
        Logger.error('Request may have validation errors. Check backend logs for details.');
        
        // Check if it's a specific validation error
        if (e.toString().contains('400')) {
          throw Exception('Invalid request data. Please check all required fields are filled correctly.');
        }
      }
      
      rethrow;
    }
  }

  /// Submit a request to join an existing provider
  Future<Map<String, dynamic>> requestToJoinExistingProvider({
    required String providerId,
    required String requestMessage,
  }) async {
    try {
      final response = await _apiService.post(
        '/role-change-requests',
        data: {
          'request_type': 'join_existing_provider',
          'provider_id': providerId,
          'request_message': requestMessage,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to submit join provider request');
    } catch (e) {
      Logger.error('Failed to submit join provider request: $e');
      rethrow;
    }
  }

  /// Get user's role change requests
  Future<List<RoleChangeRequest>> getMyRoleChangeRequests() async {
    try {
      final response = await _apiService.get('/role-change-requests/my');
      
      if (response.statusCode == 200) {
        // Handle both List and Map responses
        dynamic responseData = response.data;
        
        // If response is a Map, try to extract the data array
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data') && responseData['data'] is List) {
            responseData = responseData['data'];
          } else if (responseData.containsKey('requests') && responseData['requests'] is List) {
            responseData = responseData['requests'];
          } else {
            // If it's a Map but not containing a list, return empty list
            Logger.warning('⚠️ API returned Map instead of List for role change requests');
            return [];
          }
        }
        
        // If response is a List, process it
        if (responseData is List) {
          return responseData.map((json) => RoleChangeRequest.fromJson(json)).toList();
        }
        
        // If we get here, the response format is unexpected
        Logger.warning('⚠️ Unexpected response format for role change requests: ${responseData.runtimeType}');
        return [];
      }
      throw Exception('Failed to load role change requests');
    } catch (e) {
      Logger.error('Failed to load role change requests: $e');
      // Return empty list instead of rethrowing to prevent app crashes
      return [];
    }
  }

  /// Cancel a role change request
  Future<void> cancelRoleChangeRequest(String requestId) async {
    try {
      final response = await _apiService.delete('/role-change-requests/$requestId/cancel');
      
      if (response.statusCode != 200) {
        throw Exception('Failed to cancel role change request');
      }
    } catch (e) {
      Logger.error('Failed to cancel role change request: $e');
      rethrow;
    }
  }

  /// Get all role change requests (System Admin only)
  Future<List<RoleChangeRequest>> getAllRoleChangeRequests({
    int page = 1,
    int limit = 50,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (status != null && status.isNotEmpty) 'status': status,
      };

      final response = await _apiService.get('/role-change-requests', queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        dynamic responseData = response.data;
        
        // Handle both List and Map responses
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data') && responseData['data'] is List) {
            responseData = responseData['data'];
          } else if (responseData.containsKey('requests') && responseData['requests'] is List) {
            responseData = responseData['requests'];
          } else {
            Logger.warning('⚠️ API returned Map instead of List for all role change requests');
            return [];
          }
        }
        
        if (responseData is List) {
          return responseData.map((json) => RoleChangeRequest.fromJson(json)).toList();
        }
        
        Logger.warning('⚠️ Unexpected response format for all role change requests: ${responseData.runtimeType}');
        return [];
      }
      throw Exception('Failed to load all role change requests');
    } catch (e) {
      Logger.error('Failed to load all role change requests: $e');
      return [];
    }
  }

  /// Get role change request by ID (System Admin only)
  Future<RoleChangeRequest> getRoleChangeRequestById(String requestId) async {
    try {
      final response = await _apiService.get('/role-change-requests/$requestId');
      
      if (response.statusCode == 200) {
        return RoleChangeRequest.fromJson(response.data['request'] ?? response.data);
      }
      throw Exception('Failed to load role change request');
    } catch (e) {
      Logger.error('Failed to load role change request: $e');
      rethrow;
    }
  }

  /// Process role change request (System Admin only)
  Future<RoleChangeRequest> processRoleChangeRequest(
    String requestId,
    String status,
    String adminNotes,
  ) async {
    try {
      final response = await _apiService.put(
        '/role-change-requests/$requestId/process',
        data: {
          'status': status,
          'admin_notes': adminNotes,
        },
      );
      
      if (response.statusCode == 200) {
        Logger.info('✅ Role change request $status successfully');
        return RoleChangeRequest.fromJson(response.data['request'] ?? response.data);
      }
      throw Exception('Failed to process role change request');
    } catch (e) {
      Logger.error('Failed to process role change request: $e');
      rethrow;
    }
  }
}