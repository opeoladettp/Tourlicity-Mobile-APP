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
    return User(
      id: json['_id'] ?? json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      phoneNumber: json['phone_number'],
      profilePicture: json['profile_picture'],
      userType: json['user_type'],
      providerId: json['provider_id'],
      isActive: json['is_active'] ?? true,
      dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth']) : null,
      country: json['country'],
      gender: json['gender'],
      passportNumber: json['passport_number'],
      lastLogin: json['last_login'] != null ? DateTime.parse(json['last_login']) : null,
      createdDate: DateTime.parse(json['created_date'] ?? DateTime.now().toIso8601String()),
      updatedDate: DateTime.parse(json['updated_date'] ?? DateTime.now().toIso8601String()),
    );
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
    // Basic required fields for all users
    final hasBasicInfo = firstName != null && 
                        firstName!.isNotEmpty && 
                        lastName != null && 
                        lastName!.isNotEmpty;
    
    // For tourists, require additional travel-related information
    if (userType == 'tourist') {
      return hasBasicInfo && 
             phoneNumber != null && 
             phoneNumber!.isNotEmpty &&
             dateOfBirth != null &&
             country != null && 
             country!.isNotEmpty;
    }
    
    // For provider admins, require basic info and phone
    if (userType == 'provider_admin') {
      return hasBasicInfo && 
             phoneNumber != null && 
             phoneNumber!.isNotEmpty;
    }
    
    // For system admins, only basic info required
    return hasBasicInfo;
  }

  List<String> get missingProfileFields {
    final missing = <String>[];
    
    if (firstName == null || firstName!.isEmpty) {
      missing.add('First Name');
    }
    if (lastName == null || lastName!.isEmpty) {
      missing.add('Last Name');
    }
    
    // Role-specific requirements
    if (userType == 'tourist') {
      if (phoneNumber == null || phoneNumber!.isEmpty) {
        missing.add('Phone Number');
      }
      if (dateOfBirth == null) {
        missing.add('Date of Birth');
      }
      if (country == null || country!.isEmpty) {
        missing.add('Country');
      }
    } else if (userType == 'provider_admin') {
      if (phoneNumber == null || phoneNumber!.isEmpty) {
        missing.add('Phone Number');
      }
    }
    
    return missing;
  }

  double get profileCompletionPercentage {
    final totalFields = userType == 'tourist' ? 5 : (userType == 'provider_admin' ? 3 : 2);
    final completedFields = totalFields - missingProfileFields.length;
    return (completedFields / totalFields * 100).clamp(0.0, 100.0);
  }
  
  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
  
  // Helper getters for backward compatibility
  String? get name => fullName.isNotEmpty ? fullName : null;
  String? get phone => phoneNumber;
}