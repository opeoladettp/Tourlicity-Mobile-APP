import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';

class ProfileCompletionService {
  final AuthService _authService = AuthService();

  /// Check if user needs to complete their profile
  bool requiresProfileCompletion(User user) {
    Logger.info('🔍 Checking profile completion for user: ${user.email}');
    Logger.info('📋 Profile completion initialized:');
    Logger.info('  - First Name: "${user.firstName}"');
    Logger.info('  - Last Name: "${user.lastName}"');
    Logger.info('  - Phone: "${user.phoneNumber}"');
    Logger.info('  - Date of Birth: ${user.dateOfBirth}');
    Logger.info('  - Country: "${user.country}"');
    Logger.info('  - User Type: ${user.userType}');
    Logger.info('  - Is Profile Complete: ${user.isProfileComplete}');
    Logger.info('  - Missing Fields: ${user.missingProfileFields}');
    
    final needsCompletion = !user.isProfileComplete;
    Logger.info('  - Requires Completion: $needsCompletion');
    
    return needsCompletion;
  }

  /// Get the next required step for profile completion
  ProfileCompletionStep getNextStep(User user) {
    final missing = user.missingProfileFields;
    
    if (missing.contains('First Name') || missing.contains('Last Name')) {
      return ProfileCompletionStep.basicInfo;
    }
    
    if (user.userType == 'tourist') {
      if (missing.contains('Phone Number')) {
        return ProfileCompletionStep.contactInfo;
      }
      if (missing.contains('Date of Birth') || missing.contains('Country')) {
        return ProfileCompletionStep.personalInfo;
      }
    } else if (user.userType == 'provider_admin') {
      if (missing.contains('Phone Number')) {
        return ProfileCompletionStep.contactInfo;
      }
    }
    
    return ProfileCompletionStep.completed;
  }

  /// Update user profile with basic information
  Future<User> updateBasicInfo({
    required String firstName,
    required String lastName,
  }) async {
    Logger.info('📝 Updating basic profile information');
    
    try {
      final updatedUser = await _authService.updateProfile(
        firstName: firstName,
        lastName: lastName,
      );
      
      Logger.info('✅ Basic profile information updated successfully');
      return updatedUser;
    } catch (e) {
      Logger.error('❌ Failed to update basic profile information: $e');
      rethrow;
    }
  }

  /// Update user profile with contact information
  Future<User> updateContactInfo({
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    Logger.info('📞 Updating contact information');
    
    try {
      final updatedUser = await _authService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );
      
      Logger.info('✅ Contact information updated successfully');
      return updatedUser;
    } catch (e) {
      Logger.error('❌ Failed to update contact information: $e');
      rethrow;
    }
  }

  /// Update user profile with personal information (for tourists)
  Future<User> updatePersonalInfo({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required DateTime dateOfBirth,
    required String country,
    String? gender,
    String? passportNumber,
  }) async {
    Logger.info('🌍 Updating personal information');
    
    try {
      final updatedUser = await _authService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        country: country,
        gender: gender,
        passportNumber: passportNumber,
      );
      
      Logger.info('✅ Personal information updated successfully');
      return updatedUser;
    } catch (e) {
      Logger.error('❌ Failed to update personal information: $e');
      rethrow;
    }
  }

  /// Complete the entire profile in one step
  Future<User> completeProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    DateTime? dateOfBirth,
    String? country,
    String? gender,
    String? passportNumber,
    String? profilePicture,
  }) async {
    Logger.info('🎯 Completing full profile');
    
    try {
      final updatedUser = await _authService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        country: country,
        gender: gender,
        passportNumber: passportNumber,
        profilePicture: profilePicture,
      );
      
      Logger.info('✅ Profile completed successfully');
      return updatedUser;
    } catch (e) {
      Logger.error('❌ Failed to complete profile: $e');
      rethrow;
    }
  }

  /// Get profile completion guidance message
  String getCompletionGuidance(User user) {
    final missing = user.missingProfileFields;
    final percentage = user.profileCompletionPercentage;
    
    if (missing.isEmpty) {
      return 'Your profile is complete! 🎉';
    }
    
    final missingText = missing.length == 1 
        ? missing.first 
        : '${missing.take(missing.length - 1).join(', ')} and ${missing.last}';
    
    return 'Your profile is ${percentage.toInt()}% complete. Please add: $missingText';
  }

  /// Check if user can access the main app
  bool canAccessMainApp(User user) {
    return user.isProfileComplete && user.isActive;
  }

  /// Get list of countries for dropdown
  List<String> getCountries() {
    return [
      'Afghanistan', 'Albania', 'Algeria', 'Argentina', 'Armenia', 'Australia',
      'Austria', 'Azerbaijan', 'Bahrain', 'Bangladesh', 'Belarus', 'Belgium',
      'Bolivia', 'Bosnia and Herzegovina', 'Brazil', 'Bulgaria', 'Cambodia',
      'Canada', 'Chile', 'China', 'Colombia', 'Croatia', 'Czech Republic',
      'Denmark', 'Ecuador', 'Egypt', 'Estonia', 'Ethiopia', 'Finland',
      'France', 'Georgia', 'Germany', 'Ghana', 'Greece', 'Hungary', 'Iceland',
      'India', 'Indonesia', 'Iran', 'Iraq', 'Ireland', 'Israel', 'Italy',
      'Japan', 'Jordan', 'Kazakhstan', 'Kenya', 'Kuwait', 'Latvia', 'Lebanon',
      'Lithuania', 'Luxembourg', 'Malaysia', 'Mexico', 'Morocco', 'Netherlands',
      'New Zealand', 'Nigeria', 'Norway', 'Pakistan', 'Peru', 'Philippines',
      'Poland', 'Portugal', 'Qatar', 'Romania', 'Russia', 'Saudi Arabia',
      'Singapore', 'Slovakia', 'Slovenia', 'South Africa', 'South Korea',
      'Spain', 'Sri Lanka', 'Sweden', 'Switzerland', 'Thailand', 'Turkey',
      'Ukraine', 'United Arab Emirates', 'United Kingdom', 'United States',
      'Uruguay', 'Venezuela', 'Vietnam',
    ];
  }

  /// Get list of genders for dropdown
  List<String> getGenders() {
    return [
      'Male',
      'Female',
      'Non-binary',
      'Prefer not to say',
    ];
  }
}

enum ProfileCompletionStep {
  basicInfo,
  contactInfo,
  personalInfo,
  completed,
}

extension ProfileCompletionStepExtension on ProfileCompletionStep {
  String get title {
    switch (this) {
      case ProfileCompletionStep.basicInfo:
        return 'Basic Information';
      case ProfileCompletionStep.contactInfo:
        return 'Contact Information';
      case ProfileCompletionStep.personalInfo:
        return 'Personal Information';
      case ProfileCompletionStep.completed:
        return 'Profile Complete';
    }
  }

  String get description {
    switch (this) {
      case ProfileCompletionStep.basicInfo:
        return 'Please provide your name to get started';
      case ProfileCompletionStep.contactInfo:
        return 'Add your contact information';
      case ProfileCompletionStep.personalInfo:
        return 'Complete your travel profile';
      case ProfileCompletionStep.completed:
        return 'Your profile is complete!';
    }
  }

  int get stepNumber {
    switch (this) {
      case ProfileCompletionStep.basicInfo:
        return 1;
      case ProfileCompletionStep.contactInfo:
        return 2;
      case ProfileCompletionStep.personalInfo:
        return 3;
      case ProfileCompletionStep.completed:
        return 4;
    }
  }
}