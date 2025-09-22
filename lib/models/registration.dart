class Registration {
  final String id;
  final String customTourId;
  final String touristId;
  final String providerId;
  final String status;
  final String confirmationCode;
  final DateTime registrationDate;
  final String? notes;
  final String? specialRequirements;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String paymentStatus;
  final double? paymentAmount;
  final String? paymentCurrency;
  final DateTime createdDate;
  final DateTime updatedDate;

  Registration({
    required this.id,
    required this.customTourId,
    required this.touristId,
    required this.providerId,
    required this.status,
    required this.confirmationCode,
    required this.registrationDate,
    this.notes,
    this.specialRequirements,
    this.emergencyContactName,
    this.emergencyContactPhone,
    required this.paymentStatus,
    this.paymentAmount,
    this.paymentCurrency,
    required this.createdDate,
    required this.updatedDate,
  });

  factory Registration.fromJson(Map<String, dynamic> json) {
    // Handle nested objects
    String customTourId = json['custom_tour_id'];
    String providerId = json['provider_id'];
    
    if (json['custom_tour_id'] is Map) {
      customTourId = json['custom_tour_id']['_id'] ?? json['custom_tour_id']['id'];
    }
    
    if (json['provider_id'] is Map) {
      providerId = json['provider_id']['_id'] ?? json['provider_id']['id'];
    }

    return Registration(
      id: json['_id'] ?? json['id'],
      customTourId: customTourId,
      touristId: json['tourist_id'],
      providerId: providerId,
      status: json['status'] ?? 'pending',
      confirmationCode: json['confirmation_code'] ?? '',
      registrationDate: DateTime.parse(json['registration_date'] ?? json['created_date'] ?? DateTime.now().toIso8601String()),
      notes: json['notes'],
      specialRequirements: json['special_requirements'],
      emergencyContactName: json['emergency_contact_name'],
      emergencyContactPhone: json['emergency_contact_phone'],
      paymentStatus: json['payment_status'] ?? 'pending',
      paymentAmount: json['payment_amount']?.toDouble(),
      paymentCurrency: json['payment_currency'],
      createdDate: DateTime.parse(json['created_date'] ?? DateTime.now().toIso8601String()),
      updatedDate: DateTime.parse(json['updated_date'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'custom_tour_id': customTourId,
      'tourist_id': touristId,
      'provider_id': providerId,
      'status': status,
      'confirmation_code': confirmationCode,
      'registration_date': registrationDate.toIso8601String(),
      'notes': notes,
      'special_requirements': specialRequirements,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'payment_status': paymentStatus,
      'payment_amount': paymentAmount,
      'payment_currency': paymentCurrency,
      'created_date': createdDate.toIso8601String(),
      'updated_date': updatedDate.toIso8601String(),
    };
  }

  // Helper getters for backward compatibility
  String get userId => touristId;
  String get tourId => customTourId;
  DateTime get registeredAt => registrationDate;
}