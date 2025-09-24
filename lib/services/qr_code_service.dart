import '../models/qr_code.dart';
import '../utils/logger.dart';
import 'api_service.dart';

class QRCodeService {
  final ApiService _apiService = ApiService();

  /// Generate QR code for custom tour
  Future<QRCodeGenerationResponse> generateTourQRCode(
    String tourId, {
    bool generateJoinCode = true,
    bool notify = true,
  }) async {
    try {
      final response = await _apiService.post(
        '/qr-codes/tours/$tourId/generate',
        data: {
          'generateJoinCode': generateJoinCode,
          'notify': notify,
        },
      );

      if (response.statusCode == 200) {
        return QRCodeGenerationResponse.fromJson(response.data);
      }
      throw Exception('Failed to generate QR code');
    } catch (e) {
      Logger.error('Failed to generate tour QR code: $e');
      rethrow;
    }
  }

  /// Generate QR code for tour template
  Future<QRCodeGenerationResponse> generateTemplateQRCode(
    String templateId, {
    bool notify = true,
  }) async {
    try {
      final response = await _apiService.post(
        '/qr-codes/templates/$templateId/generate',
        data: {
          'notify': notify,
        },
      );

      if (response.statusCode == 200) {
        return QRCodeGenerationResponse.fromJson(response.data);
      }
      throw Exception('Failed to generate template QR code');
    } catch (e) {
      Logger.error('Failed to generate template QR code: $e');
      rethrow;
    }
  }

  /// Regenerate QR code for tour
  Future<QRCodeGenerationResponse> regenerateTourQRCode(String tourId) async {
    try {
      final response = await _apiService.put('/qr-codes/tours/$tourId/regenerate');

      if (response.statusCode == 200) {
        return QRCodeGenerationResponse.fromJson(response.data);
      }
      throw Exception('Failed to regenerate QR code');
    } catch (e) {
      Logger.error('Failed to regenerate tour QR code: $e');
      rethrow;
    }
  }

  /// Share QR code via email
  Future<void> shareQRCode(
    String tourId, {
    required List<String> recipients,
    String? message,
    bool bulk = false,
  }) async {
    try {
      final response = await _apiService.post(
        '/qr-codes/tours/$tourId/share',
        data: {
          'recipients': recipients,
          'message': message ?? 'Check out this amazing tour!',
          'bulk': bulk,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to share QR code');
      }
    } catch (e) {
      Logger.error('Failed to share QR code: $e');
      rethrow;
    }
  }

  /// Get QR code information
  Future<QRCodeInfo> getQRCodeInfo(String tourId, {String type = 'custom'}) async {
    try {
      final response = await _apiService.get(
        '/qr-codes/tours/$tourId',
        queryParameters: {'type': type},
      );

      if (response.statusCode == 200) {
        return QRCodeInfo.fromJson(response.data);
      }
      throw Exception('Failed to get QR code info');
    } catch (e) {
      Logger.error('Failed to get QR code info: $e');
      rethrow;
    }
  }

  /// Delete QR code
  Future<void> deleteQRCode(String tourId) async {
    try {
      final response = await _apiService.delete('/qr-codes/tours/$tourId');

      if (response.statusCode != 200) {
        throw Exception('Failed to delete QR code');
      }
    } catch (e) {
      Logger.error('Failed to delete QR code: $e');
      rethrow;
    }
  }
}