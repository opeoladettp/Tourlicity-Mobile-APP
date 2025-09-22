class User {
  final String id;
  final String email;
  final String? name;
  final String? phone;
  final String? profilePicture;
  final String userType;
  final String? providerId;
  final bool isActive;
  final bool profileCompleted;
  final DateTime? lastLogin;
  final DateTime createdDate;
  final DateTime updatedDate;

  User({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.profilePicture,
    required this.userType,
    this.providerId,
    required this.isActive,
    required this.profileCompleted,
    this.lastLogin,
    required this.createdDate,
    required this.updatedDate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'],
      email: json['email'],
      name: '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
      phone: json['phone'],
      profilePicture: json['profile_picture'],
      userType: json['user_type'],
      providerId: json['provider_id'],
      isActive: json['is_active'] ?? true,
      profileCompleted: json['profile_completed'] ?? 
          (json['first_name'] != null && json['last_name'] != null),
      lastLogin: json['last_login'] != null ? DateTime.parse(json['last_login']) : null,
      createdDate: DateTime.parse(json['created_date'] ?? DateTime.now().toIso8601String()),
      updatedDate: DateTime.parse(json['updated_date'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'profile_picture': profilePicture,
      'user_type': userType,
      'provider_id': providerId,
      'is_active': isActive,
      'profile_completed': profileCompleted,
      'last_login': lastLogin?.toIso8601String(),
      'created_date': createdDate.toIso8601String(),
      'updated_date': updatedDate.toIso8601String(),
    };
  }

  bool get isProfileComplete => profileCompleted;
  
  String get fullName => name ?? '';
  
  // Helper getters for backward compatibility
  String? get firstName => name?.split(' ').first;
  String? get lastName => name?.split(' ').skip(1).join(' ');
}