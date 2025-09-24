class QRCodeInfo {
  final bool hasQrCode;
  final String? qrCodeUrl;
  final bool hasJoinQrCode;
  final String? joinQrCodeUrl;
  final DateTime? generatedAt;
  final String? tourName;
  final String? tourId;
  final String? joinCode;

  QRCodeInfo({
    required this.hasQrCode,
    this.qrCodeUrl,
    required this.hasJoinQrCode,
    this.joinQrCodeUrl,
    this.generatedAt,
    this.tourName,
    this.tourId,
    this.joinCode,
  });

  factory QRCodeInfo.fromJson(Map<String, dynamic> json) {
    return QRCodeInfo(
      hasQrCode: json['has_qr_code'] ?? false,
      qrCodeUrl: json['qr_code_url'],
      hasJoinQrCode: json['has_join_qr_code'] ?? false,
      joinQrCodeUrl: json['join_qr_code_url'],
      generatedAt: json['generated_at'] != null 
          ? DateTime.parse(json['generated_at']) 
          : null,
      tourName: json['tour_name'],
      tourId: json['tour_id'],
      joinCode: json['join_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'has_qr_code': hasQrCode,
      'qr_code_url': qrCodeUrl,
      'has_join_qr_code': hasJoinQrCode,
      'join_qr_code_url': joinQrCodeUrl,
      'generated_at': generatedAt?.toIso8601String(),
      'tour_name': tourName,
      'tour_id': tourId,
      'join_code': joinCode,
    };
  }
}

class QRCodeGenerationResponse {
  final String message;
  final String? qrCodeUrl;
  final String? joinQrCodeUrl;
  final DateTime generatedAt;

  QRCodeGenerationResponse({
    required this.message,
    this.qrCodeUrl,
    this.joinQrCodeUrl,
    required this.generatedAt,
  });

  factory QRCodeGenerationResponse.fromJson(Map<String, dynamic> json) {
    return QRCodeGenerationResponse(
      message: json['message'] ?? '',
      qrCodeUrl: json['qr_code_url'],
      joinQrCodeUrl: json['join_qr_code_url'],
      generatedAt: DateTime.parse(json['generated_at']),
    );
  }
}