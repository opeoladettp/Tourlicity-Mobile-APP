import 'custom_tour.dart';

class Registration {
  final String id;
  final String customTourId;
  final CustomTour? customTour; // Populated tour data from API
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
    this.customTour,
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
    String customTourId;
    CustomTour? customTour;
    String providerId;
    
    // Handle custom_tour_id - can be string or populated object
    if (json['custom_tour_id'] is Map) {
      final tourData = json['custom_tour_id'] as Map<String, dynamic>;
      customTourId = tourData['_id'] ?? tourData['id'] ?? '';
      customTour = CustomTour.fromJson(tourData);
    } else {
      customTourId = json['custom_tour_id'] ?? '';
    }
    
    // Handle provider_id - can be string or populated object
    if (json['provider_id'] is Map) {
      providerId = json['provider_id']['_id'] ?? json['provider_id']['id'] ?? '';
    } else {
      providerId = json['provider_id'] ?? '';
    }

    return Registration(
      id: json['_id'] ?? json['id'] ?? '',
      customTourId: customTourId,
      customTour: customTour,
      touristId: json['tourist_id'] ?? '',
      providerId: providerId,
      status: json['status'] ?? 'pending',
      confirmationCode: json['confirmation_code'] ?? '',
      registrationDate: DateTime.tryParse(json['registration_date'] ?? json['created_date'] ?? '') ?? DateTime.now(),
      notes: json['notes'],
      specialRequirements: json['special_requirements'],
      emergencyContactName: json['emergency_contact_name'],
      emergencyContactPhone: json['emergency_contact_phone'],
      paymentStatus: json['payment_status'] ?? 'pending',
      paymentAmount: json['payment_amount']?.toDouble(),
      paymentCurrency: json['payment_currency'],
      createdDate: DateTime.tryParse(json['created_date'] ?? '') ?? DateTime.now(),
      updatedDate: DateTime.tryParse(json['updated_date'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'custom_tour_id': customTour?.toJson() ?? customTourId,
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