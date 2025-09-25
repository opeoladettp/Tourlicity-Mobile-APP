import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tour_provider.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/app_bar_actions.dart';
import '../../widgets/common/image_picker_widget.dart';
import '../../widgets/common/multiple_image_picker_widget.dart';
import '../../services/tour_template_service.dart';
import '../../models/tour_template.dart';
import '../../utils/logger.dart';

class TourManagementScreen extends StatefulWidget {
  const TourManagementScreen({super.key});

  @override
  State<TourManagementScreen> createState() => _TourManagementScreenState();
}

class _TourManagementScreenState extends State<TourManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxTouristsController = TextEditingController(text: '15');
  final _groupChatLinkController = TextEditingController();
  final TourTemplateService _tourTemplateService = TourTemplateService();

  DateTime? _startDate;
  DateTime? _endDate;
  String _status = 'draft';
  TourTemplate? _selectedTemplate;
  List<TourTemplate> _availableTemplates = [];
  bool _isLoadingTemplates = false;

  // Image fields
  String? _featuresImageUrl;
  List<String> _teaserImageUrls = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableTemplates();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _maxTouristsController.dispose();
    _groupChatLinkController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableTemplates() async {
    setState(() {
      _isLoadingTemplates = true;
    });

    try {
      final templates = await _tourTemplateService.getActiveTourTemplates();
      Logger.debug('Loaded ${templates.length} active tour templates');
      for (var template in templates) {
        Logger.debug(
          'Template - ${template.templateName} (Active: ${template.isActive})',
        );
      }
      setState(() {
        _availableTemplates = templates;
      });
    } catch (e) {
      Logger.error('Error loading templates: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load tour templates: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingTemplates = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tour Management'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveTour,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
          const BothActions(),
        ],
      ),
      body: Consumer<TourProvider>(
        builder: (context, tourProvider, child) {
          return LoadingOverlay(
            isLoading: tourProvider.isLoading,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tour Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a tour name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Tour Template Selection
                    _isLoadingTemplates
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<TourTemplate>(
                            initialValue: _selectedTemplate,
                            decoration: const InputDecoration(
                              labelText: 'Tour Template (Optional)',
                              border: OutlineInputBorder(),
                              helperText:
                                  'Select a template to pre-fill tour details',
                            ),
                            items: [
                              const DropdownMenuItem<TourTemplate>(
                                value: null,
                                child: Text('No Template - Create Custom Tour'),
                              ),
                              ..._availableTemplates.map(
                                (template) => DropdownMenuItem<TourTemplate>(
                                  value: template,
                                  child: Text(template.templateName),
                                ),
                              ),
                            ],
                            onChanged: (template) {
                              setState(() {
                                _selectedTemplate = template;
                                if (template != null) {
                                  _nameController.text = template.templateName;
                                  _descriptionController.text =
                                      template.description;
                                  _startDate = template.startDate;
                                  _endDate = template.endDate;
                                  _featuresImageUrl = template.featuresImage;
                                  _teaserImageUrls = List.from(
                                    template.teaserImages,
                                  );
                                }
                              });
                            },
                          ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _maxTouristsController,
                      decoration: const InputDecoration(
                        labelText: 'Maximum Tourists',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter maximum tourists';
                        }
                        final number = int.tryParse(value);
                        if (number == null || number < 1 || number > 100) {
                          return 'Please enter a number between 1 and 100';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _groupChatLinkController,
                      decoration: const InputDecoration(
                        labelText: 'Group Chat Link (Optional)',
                        border: OutlineInputBorder(),
                        helperText:
                            'WhatsApp, Telegram, or other group chat link',
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'draft', child: Text('Draft')),
                        DropdownMenuItem(
                          value: 'published',
                          child: Text('Published'),
                        ),
                        DropdownMenuItem(
                          value: 'completed',
                          child: Text('Completed'),
                        ),
                        DropdownMenuItem(
                          value: 'cancelled',
                          child: Text('Cancelled'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _status = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, true),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Date',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _startDate != null
                                    ? _formatDate(_startDate!)
                                    : 'Select date',
                                style: TextStyle(
                                  color: _startDate != null
                                      ? null
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, false),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'End Date',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _endDate != null
                                    ? _formatDate(_endDate!)
                                    : 'Select date',
                                style: TextStyle(
                                  color: _endDate != null ? null : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Features Image Section
                    ImagePickerWidget(
                      initialImageUrl: _featuresImageUrl,
                      onImageSelected: (url) {
                        setState(() {
                          _featuresImageUrl = url;
                        });
                      },
                      imageType: 'features',
                      label: 'Features Image',
                      isRequired: false,
                      height: 200,
                    ),
                    const SizedBox(height: 24),

                    // Teaser Images Section
                    MultipleImagePickerWidget(
                      initialImageUrls: _teaserImageUrls,
                      onImagesChanged: (urls) {
                        setState(() {
                          _teaserImageUrls = urls;
                        });
                      },
                      imageType: 'teaser',
                      label: 'Teaser Images',
                      maxImages: 5,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: tourProvider.isLoading ? null : _saveTour,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Create Tour'),
                      ),
                    ),
                    if (tourProvider.error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(244, 67, 54, 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color.fromRGBO(244, 67, 54, 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                tourProvider.error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // If end date is before start date, clear it
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _saveTour() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final tourProvider = Provider.of<TourProvider>(context, listen: false);

      // Get the current user's provider ID
      final currentUser = authProvider.user;
      if (currentUser?.providerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error: No provider ID found. Please contact support.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final success = await tourProvider.createTour(
        providerId: currentUser!.providerId!,
        tourName: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        tourTemplateId: _selectedTemplate?.id,
        startDate: _startDate,
        endDate: _endDate,
        maxTourists: int.parse(_maxTouristsController.text.trim()),
        groupChatLink: _groupChatLinkController.text.trim().isEmpty
            ? null
            : _groupChatLinkController.text.trim(),
        featuresImage: _featuresImageUrl,
        teaserImages: _teaserImageUrls.isEmpty ? null : _teaserImageUrls,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tour created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
