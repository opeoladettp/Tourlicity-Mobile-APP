import 'package:flutter/foundation.dart';
import '../models/tour.dart';
import '../services/tour_service.dart';
import '../utils/logger.dart';

class TourProvider with ChangeNotifier {
  final TourService _tourService = TourService();

  List<Tour> _tours = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _providerStats;

  List<Tour> get tours => _tours;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get providerStats => _providerStats;

  Future<void> loadMyTours() async {
    _setLoading(true);
    _clearError();

    try {
      _tours = await _tourService.getMyTours();
      notifyListeners();
    } catch (e) {
      Logger.warning('⚠️ Failed to load tours (offline mode): $e');
      // In offline mode, just set empty tours list instead of showing error
      _tours = [];
      // Don't set error for network timeouts in offline mode
      if (!e.toString().contains('connection timeout') && 
          !e.toString().contains('Connection refused')) {
        _setError(e.toString());
      }
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadProviderTours() async {
    _setLoading(true);
    _clearError();

    try {
      _tours = await _tourService.getProviderTours();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<Tour?> searchTourByJoinCode(String joinCode) async {
    _setLoading(true);
    _clearError();

    try {
      final tour = await _tourService.searchTourByJoinCode(joinCode);
      return tour;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> registerForTour(String customTourId, {String? notes}) async {
    _setLoading(true);
    _clearError();

    try {
      await _tourService.registerForTour(customTourId, notes: notes);
      await loadMyTours(); // Refresh the list
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> unregisterFromTour(String registrationId) async {
    _setLoading(true);
    _clearError();

    try {
      await _tourService.unregisterFromTour(registrationId);
      await loadMyTours(); // Refresh the list
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createTour({
    required String providerId,
    required String name,
    String? description,
    String? templateId,
    DateTime? startDate,
    DateTime? endDate,
    int maxTourists = 15,
    String? groupChatLink,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _tourService.createTour(
        providerId: providerId,
        name: name,
        description: description,
        templateId: templateId,
        startDate: startDate,
        endDate: endDate,
        maxTourists: maxTourists,
        groupChatLink: groupChatLink,
      );
      await loadProviderTours(); // Refresh the list
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateTour(
    String tourId, {
    String? name,
    String? description,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _tourService.updateTour(
        tourId,
        name: name,
        description: description,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );
      await loadProviderTours(); // Refresh the list
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteTour(String tourId) async {
    _setLoading(true);
    _clearError();

    try {
      await _tourService.deleteTour(tourId);
      await loadProviderTours(); // Refresh the list
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadProviderStats() async {
    _setLoading(true);
    _clearError();

    try {
      _providerStats = await _tourService.getProviderStats();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
