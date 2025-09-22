import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/provider_service.dart';
import '../../utils/logger.dart';
import '../../config/routes.dart';
import '../../widgets/common/navigation_drawer.dart' as nav;

class ProviderRegistrationScreen extends StatefulWidget {
  const ProviderRegistrationScreen({super.key});

  @override
  State<ProviderRegistrationScreen> createState() =>
      _ProviderRegistrationScreenState();
}

class _ProviderRegistrationScreenState
    extends State<ProviderRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _businessDescriptionController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _businessEmailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _experienceController = TextEditingController();

  String _selectedBusinessType = 'tour_operator';
  bool _isLoading = false;

  final List<Map<String, String>> _businessTypes = [
    {'value': 'tour_operator', 'label': 'Tour Operator'},
    {'value': 'travel_agency', 'label': 'Travel Agency'},
    {'value': 'local_guide', 'label': 'Local Guide'},
    {'value': 'hotel_resort', 'label': 'Hotel/Resort'},
    {'value': 'restaurant', 'label': 'Restaurant'},
    {'value': 'activity_provider', 'label': 'Activity Provider'},
    {'value': 'transportation', 'label': 'Transportation Service'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    _businessAddressController.dispose();
    _businessPhoneController.dispose();
    _businessEmailController.dispose();
    _websiteController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Become a Provider'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      drawer: nav.NavigationDrawer(
        currentRoute: AppRoutes.providerRegistration,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Card(
                color: const Color.fromRGBO(99, 102, 241, 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.business,
                            size: 32,
                            color: Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Join as a Service Provider',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Share your expertise and create amazing experiences for tourists. Fill out the form below to get started.',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Business Information Section
              const Text(
                'Business Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  labelText: 'Business Name *',
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Business name is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedBusinessType,
                decoration: const InputDecoration(
                  labelText: 'Business Type *',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _businessTypes.map((type) {
                  return DropdownMenuItem(
                    value: type['value'],
                    child: Text(type['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBusinessType = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _businessDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Business Description *',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Business description is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _businessAddressController,
                decoration: const InputDecoration(
                  labelText: 'Business Address *',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Business address is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Contact Information Section
              const Text(
                'Contact Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _businessPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Business Phone *',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Business phone is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _businessEmailController,
                decoration: const InputDecoration(
                  labelText: 'Business Email *',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Business email is required';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(
                  labelText: 'Website (Optional)',
                  prefixIcon: Icon(Icons.web),
                ),
                keyboardType: TextInputType.url,
              ),

              const SizedBox(height: 24),

              // Experience Section
              const Text(
                'Experience & Expertise',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _experienceController,
                decoration: const InputDecoration(
                  labelText: 'Tell us about your experience *',
                  prefixIcon: Icon(Icons.star),
                  hintText:
                      'Years of experience, specializations, certifications, etc.',
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe your experience';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Submit Application',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Info Card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'What happens next?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Your application will be reviewed by our team\n'
                        '• We may contact you for additional information\n'
                        '• Once approved, you\'ll receive provider access\n'
                        '• You can then start creating and managing tours',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final providerService = ProviderService();

      final applicationData = {
        'user_id': user.id,
        'business_name': _businessNameController.text.trim(),
        'business_type': _selectedBusinessType,
        'business_description': _businessDescriptionController.text.trim(),
        'business_address': _businessAddressController.text.trim(),
        'business_phone': _businessPhoneController.text.trim(),
        'business_email': _businessEmailController.text.trim(),
        'website': _websiteController.text.trim(),
        'experience': _experienceController.text.trim(),
        'status': 'pending',
        'application_date': DateTime.now().toIso8601String(),
      };

      await providerService.submitProviderApplication(applicationData);

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      Logger.error('Error submitting provider application: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting application: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Application Submitted!'),
          ],
        ),
        content: const Text(
          'Thank you for your interest in becoming a provider! '
          'Your application has been submitted successfully. '
          'Our team will review it and get back to you within 2-3 business days.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              context.pop(); // Go back to dashboard
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Back to Dashboard'),
          ),
        ],
      ),
    );
  }
}
