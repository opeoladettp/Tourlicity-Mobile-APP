import '../models/user.dart';
import '../utils/logger.dart';
import 'api_service.dart';

class UserManagementService {
  final ApiService _apiService = ApiService();

  /// Get all users (System Admin only)
  Future<List<User>> getAllUsers({
    int page = 1,
    int limit = 10,
    String? search,
    String? userType,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (userType != null && userType.isNotEmpty) 'user_type': userType,
        if (isActive != null) 'is_active': isActive,
      };

      final response = await _apiService.get('/users', queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        dynamic responseData = response.data;
        
        // Handle both List and Map responses
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data') && responseData['data'] is List) {
            responseData = responseData['data'];
          } else if (responseData.containsKey('users') && responseData['users'] is List) {
            responseData = responseData['users'];
          } else {
            return [];
          }
        }
        
        if (responseData is List) {
          return responseData.map((json) => User.fromJson(json)).toList();
        }
        
        return [];
      }
      throw Exception('Failed to load users');
    } catch (e) {
      Logger.error('Failed to load users: $e');
      return [];
    }
  }

  /// Get user by ID (System Admin only)
  Future<User> getUserById(String id) async {
    final response = await _apiService.get('/users/$id');
    
    if (response.statusCode == 200) {
      return User.fromJson(response.data['user'] ?? response.data);
    }
    throw Exception('Failed to load user');
  }

  /// Update user (System Admin only)
  Future<User> updateUser(
    String id, {
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? userType,
    bool? isActive,
    String? country,
    String? gender,
    DateTime? dateOfBirth,
    String? passportNumber,
  }) async {
    final requestData = <String, dynamic>{};
    
    if (firstName != null) requestData['first_name'] = firstName;
    if (lastName != null) requestData['last_name'] = lastName;
    if (email != null) requestData['email'] = email;
    if (phoneNumber != null) requestData['phone_number'] = phoneNumber;
    if (userType != null) requestData['user_type'] = userType;
    if (isActive != null) requestData['is_active'] = isActive;
    if (country != null) requestData['country'] = country;
    if (gender != null) requestData['gender'] = gender;
    if (dateOfBirth != null) requestData['date_of_birth'] = dateOfBirth.toIso8601String().split('T')[0];
    if (passportNumber != null) requestData['passport_number'] = passportNumber;

    final response = await _apiService.put('/users/$id', data: requestData);
    
    if (response.statusCode == 200) {
      return User.fromJson(response.data['user'] ?? response.data);
    }
    throw Exception('Failed to update user');
  }

  /// Delete user (System Admin only)
  Future<void> deleteUser(String id) async {
    final response = await _apiService.delete('/users/$id');
    
    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
  }

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final response = await _apiService.get('/users/stats');
      
      if (response.statusCode == 200) {
        return response.data['stats'] ?? response.data;
      }
      return {};
    } catch (e) {
      Logger.error('Failed to load user statistics: $e');
      return {};
    }
  }
}