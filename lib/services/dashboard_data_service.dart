import '../models/tour.dart';
import '../models/registration.dart';
import '../utils/logger.dart';
import 'tour_service.dart';
import 'user_service.dart';
import 'provider_service.dart';

class DashboardDataService {
  final TourService _tourService = TourService();
  final UserService _userService = UserService();
  final ProviderService _providerService = ProviderService();

  /// Load complete dashboard data for tourists
  Future<Map<String, dynamic>> loadTouristDashboard() async {
    try {
      Logger.info('🔄 Loading tourist dashboard data...');
      
      // Load data in parallel for better performance
      final results = await Future.wait([
        _loadUserStats(),
        _loadMyTours(),
        _loadRecommendedTours(),
      ]);

      final userStats = results[0] as Map<String, dynamic>;
      final myTours = results[1] as List<Tour>;
      final recommendedTours = results[2] as List<Tour>;

      Logger.info('✅ Dashboard data loaded successfully');
      
      return {
        'stats': userStats,
        'myTours': myTours,
        'recommendedTours': recommendedTours,
        'loadedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('❌ Failed to load dashboard data: $e');
      return _getEmptyDashboardData();
    }
  }

  /// Load complete dashboard data for provider admins
  Future<Map<String, dynamic>> loadProviderDashboard() async {
    try {
      Logger.info('🔄 Loading provider dashboard data...');
      
      final results = await Future.wait([
        _loadProviderStats(),
        _loadProviderTours(),
        _loadProviderRegistrations(),
      ]);

      final providerStats = results[0] as Map<String, dynamic>;
      final providerTours = results[1] as List<Tour>;
      final registrations = results[2] as List<Registration>;

      Logger.info('✅ Provider dashboard data loaded successfully');
      
      return {
        'stats': providerStats,
        'tours': providerTours,
        'registrations': registrations,
        'loadedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('❌ Failed to load provider dashboard data: $e');
      return _getEmptyProviderDashboardData();
    }
  }

  /// Load user statistics from API
  Future<Map<String, dynamic>> _loadUserStats() async {
    try {
      return await _userService.getUserDashboard();
    } catch (e) {
      Logger.warning('⚠️ Failed to load user stats: $e');
      return {
        'total_registrations': 0,
        'active_tours': 0,
        'completed_tours': 0,
        'upcoming_tours': [],
      };
    }
  }

  /// Load user's registered tours
  Future<List<Tour>> _loadMyTours() async {
    try {
      final tours = await _tourService.getMyTours();
      Logger.info('📋 Loaded ${tours.length} user tours');
      return tours;
    } catch (e) {
      Logger.warning('⚠️ Failed to load my tours: $e');
      return [];
    }
  }

  /// Load recommended tours for the user
  Future<List<Tour>> _loadRecommendedTours() async {
    try {
      // Get all available tours
      final allTours = await _tourService.getProviderTours();
      
      // Filter for published tours with available spots
      final recommended = allTours.where((tour) => 
        tour.status == 'published' && 
        tour.remainingTourists > 0
      ).take(10).toList();
      
      Logger.info('🎯 Loaded ${recommended.length} recommended tours');
      return recommended;
    } catch (e) {
      Logger.warning('⚠️ Failed to load recommended tours: $e');
      return [];
    }
  }

  /// Load provider statistics
  Future<Map<String, dynamic>> _loadProviderStats() async {
    try {
      return await _providerService.getRegistrationStats();
    } catch (e) {
      Logger.warning('⚠️ Failed to load provider stats: $e');
      return {
        'total_tours': 0,
        'active_tours': 0,
        'total_registrations': 0,
        'pending_registrations': 0,
      };
    }
  }

  /// Load provider's tours
  Future<List<Tour>> _loadProviderTours() async {
    try {
      final tours = await _tourService.getProviderTours();
      Logger.info('🏢 Loaded ${tours.length} provider tours');
      return tours;
    } catch (e) {
      Logger.warning('⚠️ Failed to load provider tours: $e');
      return [];
    }
  }

  /// Load provider's registrations
  Future<List<Registration>> _loadProviderRegistrations() async {
    try {
      final registrations = await _providerService.getProviderRegistrations();
      Logger.info('📝 Loaded ${registrations.length} registrations');
      return registrations;
    } catch (e) {
      Logger.warning('⚠️ Failed to load registrations: $e');
      return [];
    }
  }

  /// Get empty dashboard data structure for error cases
  Map<String, dynamic> _getEmptyDashboardData() {
    return {
      'stats': {
        'total_registrations': 0,
        'active_tours': 0,
        'completed_tours': 0,
        'upcoming_tours': [],
      },
      'myTours': <Tour>[],
      'recommendedTours': <Tour>[],
      'loadedAt': DateTime.now().toIso8601String(),
      'error': true,
    };
  }

  /// Get empty provider dashboard data structure for error cases
  Map<String, dynamic> _getEmptyProviderDashboardData() {
    return {
      'stats': {
        'total_tours': 0,
        'active_tours': 0,
        'total_registrations': 0,
        'pending_registrations': 0,
      },
      'tours': <Tour>[],
      'registrations': <Registration>[],
      'loadedAt': DateTime.now().toIso8601String(),
      'error': true,
    };
  }

  /// Check if backend is available
  Future<bool> isBackendAvailable() async {
    try {
      final userStats = await _userService.getUserDashboard();
      return userStats.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get backend health status
  Future<Map<String, dynamic>> getBackendHealth() async {
    try {
      // Try a simple API call to check connectivity
      await _userService.getUserDashboard();
      return {
        'status': 'healthy',
        'message': 'Backend is responding',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'message': 'Backend is not responding: ${e.toString()}',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}