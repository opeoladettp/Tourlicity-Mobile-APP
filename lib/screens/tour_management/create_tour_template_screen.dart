import 'package:flutter/material.dart';
import '../../widgets/common/image_picker_widget.dart';
import '../../widgets/common/multiple_image_picker_widget.dart';
import '../../services/tour_template_service.dart';
import '../../utils/logger.dart';

class CreateTourTemplateScreen extends StatefulWidget {
  const CreateTourTemplateScreen({super.key});

  @override
  State<CreateTourTemplateScreen> createState() =>
      _CreateTourTemplateScreenState();
}

class _CreateTourTemplateScreenState extends State<CreateTourTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _templateNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tourTemplateService = TourTemplateService();

  String? _featuresImageUrl;
  List<String> _teaserImageUrls = [];
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _templateNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Reset end date if it's before start date
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_featuresImageUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please add a features image'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (_startDate == null || _endDate == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select start and end dates'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        // Calculate duration in days
        final durationDays = _endDate!.difference(_startDate!).inDays + 1;

        final tourTemplateData = {
          'template_name': _templateNameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'start_date': _startDate!.toIso8601String(),
          'end_date': _endDate!.toIso8601String(),
          'duration_days': durationDays,
          'features_image': _featuresImageUrl,
          'teaser_images': _teaserImageUrls,
          'web_links': [], // Empty for now, can be added later
          'is_active': true, // Default to active
        };

        Logger.info('Creating tour template with data: $tourTemplateData');

        final createdTemplate = await _tourTemplateService.createTourTemplate(
          tourTemplateData,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tour template created successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate back to previous screen
          Navigator.of(context).pop(createdTemplate);
        }
      } catch (e) {
        Logger.error('Failed to create tour template: $e');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create tour template: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Tour Template'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Template Name
              TextFormField(
                controller: _templateNameController,
                decoration: const InputDecoration(
                  labelText: 'Template Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Template name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date Selection
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Start Date *',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _startDate != null
                                  ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                  : 'Select start date',
                              style: TextStyle(
                                fontSize: 16,
                                color: _startDate != null
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'End Date *',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _endDate != null
                                  ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                  : 'Select end date',
                              style: TextStyle(
                                fontSize: 16,
                                color: _endDate != null
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Features Image
              ImagePickerWidget(
                initialImageUrl: _featuresImageUrl,
                onImageSelected: (url) {
                  setState(() {
                    _featuresImageUrl = url;
                  });
                },
                imageType: 'features',
                label: 'Features Image',
                isRequired: true,
                height: 200,
              ),
              const SizedBox(height: 24),

              // Teaser Images
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

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Creating...', style: TextStyle(fontSize: 16)),
                          ],
                        )
                      : const Text(
                          'Create Tour Template',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
