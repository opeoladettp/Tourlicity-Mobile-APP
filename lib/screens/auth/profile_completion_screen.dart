import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../config/routes.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/safe_bottom_padding.dart';
import '../../models/user.dart';
import '../../utils/logger.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _basicInfoFormKey = GlobalKey<FormState>();
  final _contactInfoFormKey = GlobalKey<FormState>();
  final _personalInfoFormKey = GlobalKey<FormState>();
  final _pageController = PageController();

  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passportController = TextEditingController();
  final _profilePictureController = TextEditingController();

  // Form data
  DateTime? _selectedDateOfBirth;
  String? _selectedCountry;
  String? _selectedGender;

  int _currentStep = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null) {
      _firstNameController.text = user.firstName ?? '';
      _lastNameController.text = user.lastName ?? '';
      _phoneController.text = user.phoneNumber ?? '';
      _passportController.text = user.passportNumber ?? '';
      _profilePictureController.text = user.profilePicture ?? '';
      _selectedDateOfBirth = user.dateOfBirth;
      _selectedCountry = user.country;
      _selectedGender = user.gender;

      // Always start from step 0 to ensure proper flow
      // Users can navigate through all steps even if some info is pre-filled
      _currentStep = 0;
      
      Logger.info('📋 Profile completion initialized:');
      Logger.info('  - First Name: "${user.firstName}"');
      Logger.info('  - Last Name: "${user.lastName}"');
      Logger.info('  - Phone: "${user.phoneNumber}"');
      Logger.info('  - Starting at step: $_currentStep');
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _passportController.dispose();
    _profilePictureController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressIndicator(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildBasicInfoStep(),
                    _buildContactInfoStep(),
                    _buildPersonalInfoStep(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 48), // Spacer
              const Icon(Icons.person_add_rounded, size: 64, color: Colors.blue),
              // Debug button
              IconButton(
                onPressed: () async {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  Logger.info('🐛 DEBUG: Force refreshing user data...');
                  await authProvider.forceRefreshUserData();
                  authProvider.debugProfileStatus();
                  
                  // Test parsing with sample database data
                  Logger.info('🧪 Testing User.fromJson with sample database data...');
                  try {
                    final sampleData = {
                      "_id": {"\$oid": "68d26ed7d0b8d61e6ba081b4"},
                      "email": "opeyemioladejobi@gmail.com",
                      "user_type": "system_admin",
                      "first_name": "Opeyemi",
                      "last_name": "Oladejobi",
                      "profile_picture": "https://lh3.googleusercontent.com/a/ACg8ocKBpsYgTn_IepwmlMSgjMtuNVOG7Tz46BMb0jPnN7-ZxB3mgBAT",
                      "is_active": true,
                      "google_id": "108374755249700857162",
                      "created_date": {"\$date": "2025-09-23T09:56:39.952Z"},
                      "updated_date": {"\$date": "2025-09-24T15:49:47.766Z"},
                      "__v": 0,
                      "country": "Nigeria",
                      "date_of_birth": {"\$date": "1991-09-04T00:00:00.000Z"},
                      "gender": "male",
                      "phone_number": "08189273082"
                    };
                    
                    final testUser = User.fromJson(sampleData);
                    Logger.info('✅ Test parsing successful: ${testUser.firstName} ${testUser.lastName}');
                  } catch (e) {
                    Logger.error('❌ Test parsing failed: $e');
                  }
                },
                icon: const Icon(Icons.bug_report, color: Colors.red),
                tooltip: 'Debug: Refresh User Data',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Complete Your Profile',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return Text(
                authProvider.getProfileCompletionGuidance(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final totalSteps = _getTotalSteps();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < totalSteps - 1 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? Colors.blue
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SafeScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _basicInfoFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Let\'s start with your name',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'First name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Last name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _profilePictureController,
              decoration: const InputDecoration(
                labelText: 'Profile Picture URL (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.photo_camera),
                hintText: 'https://example.com/your-photo.jpg',
              ),
              onChanged: (value) {
                setState(() {}); // Trigger rebuild to show/hide preview
              },
            ),
            if (_profilePictureController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Profile Picture Preview:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: NetworkImage(_profilePictureController.text.trim()),
                      onBackgroundImageError: (exception, stackTrace) {
                        // Handle image loading error
                      },
                      child: _profilePictureController.text.trim().isEmpty
                          ? const Icon(Icons.person, size: 40, color: Colors.grey)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Logger.info('🔘 Continue button pressed!');
                  _nextStep();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Continue', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoStep() {
    return SafeScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _contactInfoFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Information',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'How can we reach you?',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_outlined),
                hintText: '+1 234 567 8900',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Phone number is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousStep,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(_isLastStep() ? 'Complete' : 'Continue'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final countries = authProvider.getCountries();

    return SafeScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _personalInfoFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Help us personalize your travel experience',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            // Date of Birth
            InkWell(
              onTap: _selectDateOfBirth,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  _selectedDateOfBirth != null
                      ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                      : 'Select your date of birth',
                  style: TextStyle(
                    color: _selectedDateOfBirth != null
                        ? Colors.black87
                        : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Country
            DropdownButtonFormField<String>(
              initialValue: _selectedCountry,
              decoration: const InputDecoration(
                labelText: 'Country',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.public_outlined),
              ),
              items: countries.map((country) {
                return DropdownMenuItem(value: country, child: Text(country));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCountry = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Country is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Gender (Optional)
            DropdownButtonFormField<String>(
              initialValue: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Gender (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
                DropdownMenuItem(
                  value: 'prefer_not_to_say',
                  child: Text('Prefer not to say'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
              },
            ),
            const SizedBox(height: 16),
            // Passport Number (Optional)
            TextFormField(
              controller: _passportController,
              decoration: const InputDecoration(
                labelText: 'Passport Number (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.card_membership_outlined),
                hintText: 'For international travel',
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousStep,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _completeProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Complete Profile'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _nextStep() {
    Logger.info('🔄 _nextStep called - Current step: $_currentStep');
    
    if (_currentStep == 0) {
      // Step 0: Basic Info - validate and move to next step
      Logger.info('📝 Validating basic info form...');
      Logger.info('First name: "${_firstNameController.text}"');
      Logger.info('Last name: "${_lastNameController.text}"');
      
      final isValid = _basicInfoFormKey.currentState?.validate() ?? false;
      Logger.info('Form validation result: $isValid');
      
      if (isValid) {
        Logger.info('✅ Moving to next step');
        setState(() {
          _currentStep++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        Logger.warning('❌ Form validation failed');
      }
    } else if (_currentStep == 1) {
      // Step 1: Contact Info - validate phone and either complete or move to next step
      Logger.info('📞 Validating contact info form...');
      
      final isValid = _contactInfoFormKey.currentState?.validate() ?? false;
      Logger.info('Contact form validation result: $isValid');
      
      if (isValid) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.user?.userType != 'tourist') {
          // For non-tourists, complete profile here
          Logger.info('🏢 Non-tourist user, completing profile');
          _completeProfile();
        } else {
          // For tourists, move to personal info step
          Logger.info('🧳 Tourist user, moving to personal info step');
          setState(() {
            _currentStep++;
          });
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      } else {
        Logger.warning('❌ Contact form validation failed');
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = _selectedDateOfBirth ?? DateTime(now.year - 25);

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year - 13), // Minimum age 13
    );

    if (date != null) {
      setState(() {
        _selectedDateOfBirth = date;
      });
    }
  }

  Future<void> _completeProfile() async {
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all required fields')),
        );
      }
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // For tourists, require additional fields
    if (authProvider.user?.userType == 'tourist') {
      if (_selectedDateOfBirth == null || _selectedCountry == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Date of birth and country are required for tourists',
              ),
            ),
          );
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      await authProvider.completeProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        dateOfBirth: _selectedDateOfBirth,
        country: _selectedCountry,
        gender: _selectedGender,
        passportNumber: _passportController.text.trim().isNotEmpty
            ? _passportController.text.trim()
            : null,
        profilePicture: _profilePictureController.text.trim().isNotEmpty
            ? _profilePictureController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to unified dashboard
        if (mounted) {
          context.go(AppRoutes.dashboard);
        }
      }
    } catch (e) {
      Logger.error('Profile completion failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int _getTotalSteps() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.user?.userType == 'tourist' ? 3 : 2;
  }

  bool _isLastStep() {
    return _currentStep >= _getTotalSteps() - 1;
  }
}
