import '../utils/logger.dart';

class User {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? profilePicture;
  final String userType;
  final String? providerId;
  final bool isActive;
  final DateTime? dateOfBirth;
  final String? country;
  final String? gender;
  final String? passportNumber;
  final DateTime? lastLogin;
  final DateTime createdDate;
  final DateTime updatedDate;

  User({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.profilePicture,
    required this.userType,
    this.providerId,
    required this.isActive,
    this.dateOfBirth,
    this.country,
    this.gender,
    this.passportNumber,
    this.lastLogin,
    required this.createdDate,
    required this.updatedDate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      Logger.info('🔍 Parsing User from JSON: $json');

      // Helper function to safely extract string values
      String? safeString(dynamic value) {
        if (value == null) return null;
        if (value is String) return value;
        if (value is Map) return null; // Skip Map values that should be strings
        return value.toString();
      }

      // Debug individual field parsing
      final id = json['_id'] is Map && json['_id']['\$oid'] != null
          ? (safeString(json['_id']['\$oid']) ?? '')
          : (safeString(json['_id']) ?? safeString(json['id']) ?? '');
      final email = safeString(json['email']) ?? '';
      final firstName = safeString(json['first_name']);
      final lastName = safeString(json['last_name']);
      final phoneNumber = safeString(json['phone_number']);
      final country = safeString(json['country']);

      Logger.info('📋 Parsed fields:');
      Logger.info('  - ID: $id');
      Logger.info('  - Email: $email');
      Logger.info('  - First Name: $firstName (raw: ${json['first_name']})');
      Logger.info('  - Last Name: $lastName (raw: ${json['last_name']})');
      Logger.info('  - Phone: $phoneNumber (raw: ${json['phone_number']})');
      Logger.info('  - Country: $country (raw: ${json['country']})');

      return User(
        id: id,
        email: email,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        profilePicture: safeString(json['profile_picture']),
        userType: safeString(json['user_type']) ?? 'tourist',
        providerId: json['provider_id'] is Map
            ? safeString(json['provider_id']['_id']) ??
                  safeString(json['provider_id']['id'])
            : safeString(json['provider_id']),
        isActive: json['is_active'] ?? true,
        dateOfBirth:
            json['date_of_birth'] != null && json['date_of_birth'] is String
            ? DateTime.tryParse(json['date_of_birth'])
            : json['date_of_birth'] is Map &&
                  json['date_of_birth']['\$date'] != null
            ? DateTime.tryParse(json['date_of_birth']['\$date'])
            : null,
        country: country,
        gender: safeString(json['gender']),
        passportNumber: safeString(json['passport_number']),
        lastLogin: json['last_login'] != null && json['last_login'] is String
            ? DateTime.tryParse(json['last_login'])
            : null,
        createdDate:
            json['created_date'] is Map &&
                json['created_date']['\$date'] != null
            ? DateTime.tryParse(json['created_date']['\$date']) ??
                  DateTime.now()
            : DateTime.tryParse(
                    safeString(json['created_date']) ??
                        DateTime.now().toIso8601String(),
                  ) ??
                  DateTime.now(),
        updatedDate:
            json['updated_date'] is Map &&
                json['updated_date']['\$date'] != null
            ? DateTime.tryParse(json['updated_date']['\$date']) ??
                  DateTime.now()
            : DateTime.tryParse(
                    safeString(json['updated_date']) ??
                        DateTime.now().toIso8601String(),
                  ) ??
                  DateTime.now(),
      );
    } catch (e) {
      // Log the problematic JSON for debugging
      Logger.error('❌ Error parsing User from JSON: $e');
      Logger.error('📋 JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'profile_picture': profilePicture,
      'user_type': userType,
      'provider_id': providerId,
      'is_active': isActive,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'country': country,
      'gender': gender,
      'passport_number': passportNumber,
      'last_login': lastLogin?.toIso8601String(),
      'created_date': createdDate.toIso8601String(),
      'updated_date': updatedDate.toIso8601String(),
    };
  }

  bool get isProfileComplete {
    // Helper function to check if a string field is valid
    bool isValidString(String? value) {
      return value != null && value.trim().isNotEmpty;
    }

    // Basic required fields for all users
    final hasBasicInfo = isValidString(firstName) && isValidString(lastName);

    // For tourists, require additional travel-related information
    if (userType == 'tourist') {
      return hasBasicInfo &&
          isValidString(phoneNumber) &&
          dateOfBirth != null &&
          isValidString(country);
    }

    // For provider admins, require basic info and phone
    if (userType == 'provider_admin') {
      return hasBasicInfo && isValidString(phoneNumber);
    }

    // For system admins, only basic info required
    return hasBasicInfo;
  }

  List<String> get missingProfileFields {
    final missing = <String>[];

    // Helper function to check if a string field is valid
    bool isValidString(String? value) {
      return value != null && value.trim().isNotEmpty;
    }

    if (!isValidString(firstName)) {
      missing.add('First Name');
    }
    if (!isValidString(lastName)) {
      missing.add('Last Name');
    }

    // Role-specific requirements
    if (userType == 'tourist') {
      if (!isValidString(phoneNumber)) {
        missing.add('Phone Number');
      }
      if (dateOfBirth == null) {
        missing.add('Date of Birth');
      }
      if (!isValidString(country)) {
        missing.add('Country');
      }
    } else if (userType == 'provider_admin') {
      if (!isValidString(phoneNumber)) {
        missing.add('Phone Number');
      }
    }

    return missing;
  }

  double get profileCompletionPercentage {
    final totalFields = userType == 'tourist'
        ? 5
        : (userType == 'provider_admin' ? 3 : 2);
    final completedFields = totalFields - missingProfileFields.length;
    return (completedFields / totalFields * 100).clamp(0.0, 100.0);
  }

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  // Helper getters for backward compatibility
  String? get name => fullName.isNotEmpty ? fullName : null;
  String? get phone => phoneNumber;
}
