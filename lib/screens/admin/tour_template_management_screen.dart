import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/tour_template_service.dart';
import '../../models/tour_template.dart';
import '../../utils/logger.dart';
import '../../config/routes.dart';
import '../../widgets/common/navigation_drawer.dart' as nav;
import '../../widgets/common/app_bar_actions.dart';
import '../../widgets/common/safe_bottom_padding.dart';

class TourTemplateManagementScreen extends StatefulWidget {
  const TourTemplateManagementScreen({super.key});

  @override
  State<TourTemplateManagementScreen> createState() =>
      _TourTemplateManagementScreenState();
}

class _TourTemplateManagementScreenState
    extends State<TourTemplateManagementScreen> {
  final TourTemplateService _tourTemplateService = TourTemplateService();

  List<TourTemplate> _templates = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool? _activeFilter;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);

    try {
      final templates = await _tourTemplateService.getAllTourTemplates(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        isActive: _activeFilter,
      );
      setState(() {
        _templates = templates;
      });
    } catch (e) {
      Logger.error('Failed to load tour templates: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading templates: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tour Templates'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [
          const BothActions(),
        ],
      ),
      drawer: nav.NavigationDrawer(
        currentRoute: AppRoutes.tourTemplateManagement,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTemplateDialog(),
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadTemplates,
                    child: _buildTemplatesList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search templates...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _loadTemplates();
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Filter: '),
              FilterChip(
                label: const Text('All'),
                selected: _activeFilter == null,
                onSelected: (selected) {
                  setState(() {
                    _activeFilter = null;
                  });
                  _loadTemplates();
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Active'),
                selected: _activeFilter == true,
                onSelected: (selected) {
                  setState(() {
                    _activeFilter = true;
                  });
                  _loadTemplates();
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Inactive'),
                selected: _activeFilter == false,
                onSelected: (selected) {
                  setState(() {
                    _activeFilter = false;
                  });
                  _loadTemplates();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesList() {
    if (_templates.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No templates found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SafeListView(
      padding: const EdgeInsets.all(16),
      children: _templates.map((template) => _buildTemplateCard(template)).toList(),
    );
  }

  Widget _buildTemplateCard(TourTemplate template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Featured Image
          if (template.featuresImage != null && template.featuresImage!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                template.featuresImage!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.templateName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${template.durationDays} days • ${_formatDate(template.startDate)} - ${_formatDate(template.endDate)}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: template.isActive,
                      onChanged: (value) => _toggleTemplateStatus(template),
                      activeTrackColor: const Color(0xFF6366F1),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  template.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Image and Link indicators
                if (template.teaserImages.isNotEmpty || template.webLinks.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (template.teaserImages.isNotEmpty) ...[
                        Icon(Icons.photo_library, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${template.teaserImages.length} teaser${template.teaserImages.length == 1 ? '' : 's'}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (template.webLinks.isNotEmpty) ...[
                        Icon(Icons.link, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${template.webLinks.length} link${template.webLinks.length == 1 ? '' : 's'}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                ],
            const SizedBox(height: 12),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () => _showEditTemplateDialog(template),
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit Template',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _manageActivities(template),
                      icon: const Icon(Icons.event_note),
                      tooltip: 'Manage Activities',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _deleteTemplate(template),
                      icon: const Icon(Icons.delete),
                      tooltip: 'Delete Template',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateTemplateDialog() async {
    await _showTemplateDialog();
  }

  Future<void> _showEditTemplateDialog(TourTemplate template) async {
    await _showTemplateDialog(template: template);
  }

  Future<void> _showTemplateDialog({TourTemplate? template}) async {
    final nameController = TextEditingController(
      text: template?.templateName ?? '',
    );
    final descriptionController = TextEditingController(
      text: template?.description ?? '',
    );
    final featuredImageController = TextEditingController(
      text: template?.featuresImage ?? '',
    );
    
    DateTime startDate = template?.startDate ?? DateTime.now();
    DateTime endDate =
        template?.endDate ?? DateTime.now().add(const Duration(days: 7));
    
    List<String> teaserImages = List.from(template?.teaserImages ?? []);
    List<WebLink> webLinks = List.from(template?.webLinks ?? []);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(template == null ? 'Create Template' : 'Edit Template'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.7,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Information
                  const Text(
                    'Basic Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Template Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Date Selection
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text('Start Date'),
                          subtitle: Text(_formatDate(startDate)),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null) {
                              setState(() {
                                startDate = date;
                              });
                            }
                          },
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: const Text('End Date'),
                          subtitle: Text(_formatDate(endDate)),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: endDate,
                              firstDate: startDate,
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null) {
                              setState(() {
                                endDate = date;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Images Section
                  const Text(
                    'Images',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: featuredImageController,
                    decoration: const InputDecoration(
                      labelText: 'Featured Image URL',
                      border: OutlineInputBorder(),
                      hintText: 'https://example.com/featured-image.jpg',
                      prefixIcon: Icon(Icons.image),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Teaser Images
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Teaser Images',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      IconButton(
                        onPressed: () {
                          _showAddTeaserImageDialog(context, (imageUrl) {
                            setState(() {
                              teaserImages.add(imageUrl);
                            });
                          });
                        },
                        icon: const Icon(Icons.add),
                        tooltip: 'Add Teaser Image',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (teaserImages.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'No teaser images added',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...teaserImages.asMap().entries.map((entry) {
                      final index = entry.key;
                      final imageUrl = entry.value;
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.image),
                          title: Text(
                            imageUrl.length > 40 
                                ? '${imageUrl.substring(0, 40)}...' 
                                : imageUrl,
                          ),
                          trailing: IconButton(
                            onPressed: () {
                              setState(() {
                                teaserImages.removeAt(index);
                              });
                            },
                            icon: const Icon(Icons.delete, color: Colors.red),
                          ),
                        ),
                      );
                    }),
                  
                  const SizedBox(height: 24),
                  
                  // Web Links Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Web Links',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      IconButton(
                        onPressed: () {
                          _showAddWebLinkDialog(context, (webLink) {
                            setState(() {
                              webLinks.add(webLink);
                            });
                          });
                        },
                        icon: const Icon(Icons.add),
                        tooltip: 'Add Web Link',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (webLinks.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'No web links added',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...webLinks.asMap().entries.map((entry) {
                      final index = entry.key;
                      final webLink = entry.value;
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.link),
                          title: Text(webLink.description),
                          subtitle: Text(
                            webLink.url.length > 40 
                                ? '${webLink.url.substring(0, 40)}...' 
                                : webLink.url,
                          ),
                          trailing: IconButton(
                            onPressed: () {
                              setState(() {
                                webLinks.removeAt(index);
                              });
                            },
                            icon: const Icon(Icons.delete, color: Colors.red),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    descriptionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final templateData = {
                    'template_name': nameController.text.trim(),
                    'start_date': startDate.toIso8601String().split('T')[0],
                    'end_date': endDate.toIso8601String().split('T')[0],
                    'description': descriptionController.text.trim(),
                    'features_image': featuredImageController.text.trim().isEmpty 
                        ? null 
                        : featuredImageController.text.trim(),
                    'teaser_images': teaserImages,
                    'web_links': webLinks.map((link) => link.toJson()).toList(),
                  };

                  if (template == null) {
                    await _tourTemplateService.createTourTemplate(templateData);
                  } else {
                    await _tourTemplateService.updateTourTemplate(template.id, templateData);
                  }

                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          template == null
                              ? 'Template created successfully'
                              : 'Template updated successfully',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadTemplates();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
              child: Text(template == null ? 'Create' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleTemplateStatus(TourTemplate template) async {
    try {
      await _tourTemplateService.toggleTourTemplateStatus(template.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Template ${template.isActive ? 'deactivated' : 'activated'} successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadTemplates();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteTemplate(TourTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text(
          'Are you sure you want to delete "${template.templateName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _tourTemplateService.deleteTourTemplate(template.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Template deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadTemplates();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _manageActivities(TourTemplate template) {
    context.push('${AppRoutes.tourTemplateActivities}/${template.id}');
  }

  void _showAddTeaserImageDialog(BuildContext context, Function(String) onAdd) {
    final imageUrlController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Teaser Image'),
        content: TextField(
          controller: imageUrlController,
          decoration: const InputDecoration(
            labelText: 'Image URL',
            border: OutlineInputBorder(),
            hintText: 'https://example.com/teaser-image.jpg',
            prefixIcon: Icon(Icons.image),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final imageUrl = imageUrlController.text.trim();
              if (imageUrl.isNotEmpty) {
                onAdd(imageUrl);
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddWebLinkDialog(BuildContext context, Function(WebLink) onAdd) {
    final urlController = TextEditingController();
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Web Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                hintText: 'Official Tourism Website',
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                border: OutlineInputBorder(),
                hintText: 'https://example.com',
                prefixIcon: Icon(Icons.link),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = urlController.text.trim();
              final description = descriptionController.text.trim();
              if (url.isNotEmpty && description.isNotEmpty) {
                onAdd(WebLink(url: url, description: description));
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
