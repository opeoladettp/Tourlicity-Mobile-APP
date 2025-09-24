import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/role_change_service.dart';
import '../../models/role_change_request.dart';
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
  final _corporateTaxIdController = TextEditingController();
  final _websiteController = TextEditingController();
  final _experienceController = TextEditingController();

  String _selectedBusinessType = 'tour_operator';
  String _selectedCountry = 'United States';
  bool _isLoading = false;
  bool _isCheckingStatus = true;
  RoleChangeRequest? _existingApplication;

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

  final List<String> _countries = [
    'United States',
    'Canada',
    'United Kingdom',
    'Australia',
    'Germany',
    'France',
    'Italy',
    'Spain',
    'Japan',
    'South Korea',
    'Brazil',
    'Mexico',
    'India',
    'China',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _checkExistingApplication();
  }

  Future<void> _checkExistingApplication() async {
    try {
      // First check if user is already a provider
      final authProvider = provider_pkg.Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      
      if (user?.userType == 'provider_admin') {
        // User is already a provider, redirect to dashboard
        if (mounted) {
          context.go(AppRoutes.dashboard);
        }
        return;
      }

      final roleChangeService = RoleChangeService();
      final applications = await roleChangeService.getMyRoleChangeRequests();
      
      // Look for pending or approved provider applications
      final providerApplication = applications.firstWhere(
        (app) => app.requestType == 'become_new_provider' && 
                 (app.isPending || app.isApproved),
        orElse: () => RoleChangeRequest(
          id: '',
          requestType: '',
          status: '',
          createdDate: DateTime.now(),
        ),
      );

      setState(() {
        if (providerApplication.id.isNotEmpty) {
          _existingApplication = providerApplication;
        }
        _isCheckingStatus = false;
      });
    } catch (e) {
      Logger.error('Error checking existing applications: $e');
      setState(() {
        _isCheckingStatus = false;
      });
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    _businessAddressController.dispose();
    _businessPhoneController.dispose();
    _businessEmailController.dispose();
    _corporateTaxIdController.dispose();
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
      body: _isCheckingStatus
          ? const Center(child: CircularProgressIndicator())
          : _existingApplication != null
              ? _buildApplicationStatus()
              : _buildRegistrationForm(),
    );
  }

  Widget _buildRegistrationForm() {
    return SingleChildScrollView(
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

            // Legal & Compliance Section
            const Text(
              'Legal & Compliance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Country Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedCountry,
              decoration: const InputDecoration(
                labelText: 'Country *',
                prefixIcon: Icon(Icons.public),
              ),
              items: _countries.map((country) {
                return DropdownMenuItem(value: country, child: Text(country));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCountry = value!;
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

            // Corporate Tax ID
            TextFormField(
              controller: _corporateTaxIdController,
              decoration: const InputDecoration(
                labelText: 'Corporate Tax ID *',
                prefixIcon: Icon(Icons.business),
                hintText: 'e.g., EIN, VAT Number, Tax Registration Number',
                helperText: 'Your business tax identification number',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Corporate Tax ID is required';
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
    );
  }
  
Widget _buildApplicationStatus() {
    final application = _existingApplication!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _getStatusIcon(application.status),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Provider Application Status',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              application.statusDisplayName,
                              style: TextStyle(
                                fontSize: 16,
                                color: _getStatusColor(application.status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Application Details
                  _buildDetailRow('Application Type', application.requestTypeDisplayName),
                  _buildDetailRow('Submitted Date', _formatDate(application.createdDate)),
                  if (application.processedDate != null)
                    _buildDetailRow('Processed Date', _formatDate(application.processedDate!)),
                  
                  const SizedBox(height: 16),
                  
                  // Status Message
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getStatusColor(application.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStatusColor(application.status).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStatusMessage(application.status),
                          style: TextStyle(
                            color: _getStatusColor(application.status),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (application.adminNotes != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Admin Notes: ${application.adminNotes}',
                            style: TextStyle(
                              color: _getStatusColor(application.status),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Action Buttons
          if (application.isPending) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showCancelConfirmation(application.id),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel Application'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _refreshStatus,
              icon: const Icon(Icons.sync),
              label: const Text('Check Status'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Help Card
          Card(
            color: Colors.grey.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help_outline, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Need Help?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'If you have questions about your application status or need to update your information, please contact our support team.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Icon(Icons.hourglass_empty, color: Colors.orange, size: 32);
      case 'approved':
        return const Icon(Icons.check_circle, color: Colors.green, size: 32);
      case 'rejected':
        return const Icon(Icons.cancel, color: Colors.red, size: 32);
      default:
        return const Icon(Icons.info, color: Colors.grey, size: 32);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Your application is being reviewed by our team. We\'ll get back to you within 2-3 business days.';
      case 'approved':
        return 'Congratulations! Your application has been approved. You now have provider access.';
      case 'rejected':
        return 'Your application was not approved at this time. Please contact support for more information.';
      default:
        return 'Application status unknown. Please contact support.';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _refreshStatus() async {
    setState(() {
      _isCheckingStatus = true;
    });
    await _checkExistingApplication();
  }

  void _showCancelConfirmation(String applicationId) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Application'),
        content: const Text(
          'Are you sure you want to cancel your provider application? '
          'This action cannot be undone and you\'ll need to reapply if you change your mind.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Keep Application'),
          ),
          ElevatedButton(
            onPressed: () {
              if (mounted) {
                Navigator.of(context).pop();
                _cancelApplication(applicationId);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Application'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelApplication(String applicationId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final roleChangeService = RoleChangeService();
      await roleChangeService.cancelRoleChangeRequest(applicationId);

      if (mounted) {
        setState(() {
          _existingApplication = null;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Logger.error('Error cancelling application: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling application: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = provider_pkg.Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Debug: Log form data before submission
      Logger.info('📝 Form data being submitted:');
      Logger.info('Provider Name: ${_businessNameController.text.trim()}');
      Logger.info('Country: $_selectedCountry');
      Logger.info('Address: ${_businessAddressController.text.trim()}');
      Logger.info('Phone: ${_businessPhoneController.text.trim()}');
      Logger.info('Email: ${_businessEmailController.text.trim()}');
      Logger.info('Tax ID: ${_corporateTaxIdController.text.trim()}');
      Logger.info('Description: ${_businessDescriptionController.text.trim()}');
      Logger.info('Business Type: $_selectedBusinessType');
      Logger.info('Website: ${_websiteController.text.trim()}');
      Logger.info('Experience: ${_experienceController.text.trim()}');

      final roleChangeService = RoleChangeService();

      // Submit role change request to become a new provider
      await roleChangeService.requestToBecomeNewProvider(
        providerName: _businessNameController.text.trim(),
        country: _selectedCountry,
        address: _businessAddressController.text.trim(),
        phoneNumber: _businessPhoneController.text.trim(),
        emailAddress: _businessEmailController.text.trim(),
        corporateTaxId: _corporateTaxIdController.text.trim(),
        companyDescription: _businessDescriptionController.text.trim(),
        logoUrl: null, // Logo upload can be added later
        requestMessage:
            'Business Type: $_selectedBusinessType\n'
            'Website: ${_websiteController.text.trim()}\n'
            'Experience: ${_experienceController.text.trim()}',
      );

      if (mounted) {
        // Refresh to show the application status
        await _checkExistingApplication();
        _showSuccessDialog();
      }
    } catch (e) {
      Logger.error('Error submitting provider application: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting application: ${e.toString()}'),
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
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text('Application Submitted!'),
            ),
          ],
        ),
        content: const Text(
          'Thank you for your interest in becoming a provider! '
          'Your application has been submitted successfully. '
          'You can now track the status of your application on this page.\n\n'
          'Our team will review your information and get back to you within 2-3 business days.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (mounted) {
                Navigator.of(context).pop(); // Close dialog
                // Stay on this page to show application status
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('View Application Status'),
          ),
        ],
      ),
    );
  }
}