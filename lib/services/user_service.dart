import '../models/user.dart';
import 'api_service.dart';
import '../utils/logger.dart';

class UserService {
  final ApiService _apiService = ApiService();

  Future<List<User>> getAllUsers() async {
    try {
      final response = await _apiService.get('/users');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => User.fromJson(json)).toList();
      }
      throw Exception('Failed to load users');
    } catch (e) {
      Logger.warning('⚠️ API call failed, returning empty users list: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getUserDashboard() async {
    try {
      final response = await _apiService.get('/users/dashboard');
      if (response.statusCode == 200) {
        return response.data['dashboard'] ?? response.data;
      }
      throw Exception('Failed to load user dashboard');
    } catch (e) {
      Logger.warning('⚠️ API call failed for user dashboard: $e');
      return {
        'total_registrations': 0,
        'active_tours': 0,
        'completed_tours': 0,
        'upcoming_tours': [],
      };
    }
  }

  Future<User> getUserById(String id) async {
    final response = await _apiService.get('/users/$id');
    if (response.statusCode == 200) {
      return User.fromJson(response.data['user'] ?? response.data);
    }
    throw Exception('Failed to load user');
  }

  Future<User> updateUser(
    String id, {
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? userType,
    bool? isActive,
    String? country,
    String? gender,
  }) async {
    final data = <String, dynamic>{};
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (phoneNumber != null) data['phone_number'] = phoneNumber;
    if (userType != null) data['user_type'] = userType;
    if (isActive != null) data['is_active'] = isActive;
    if (country != null) data['country'] = country;
    if (gender != null) data['gender'] = gender;

    final response = await _apiService.put('/users/$id', data: data);
    if (response.statusCode == 200) {
      return User.fromJson(response.data['user'] ?? response.data);
    }
    throw Exception('Failed to update user');
  }

  Future<void> deleteUser(String id) async {
    final response = await _apiService.delete('/users/$id');
    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
  }
}