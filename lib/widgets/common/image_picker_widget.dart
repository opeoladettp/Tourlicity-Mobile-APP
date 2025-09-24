import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/file_picker_service.dart' as fps;
import '../../services/file_upload_service.dart';
import '../../utils/logger.dart';

class ImagePickerWidget extends StatefulWidget {
  final Function(String) onImageSelected; // URL callback
  final Function(fps.PickedFile)? onFileSelected; // File callback
  final String? initialImageUrl;
  final String? label;
  final String? hint;
  final bool required;
  final bool allowUpload;
  final double? previewSize;
  final bool showUrlInput;

  const ImagePickerWidget({
    super.key,
    required this.onImageSelected,
    this.onFileSelected,
    this.initialImageUrl,
    this.label,
    this.hint,
    this.required = false,
    this.allowUpload = true,
    this.previewSize = 80,
    this.showUrlInput = true,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final fps.FilePickerService _filePickerService = fps.FilePickerService();
  final FileUploadService _uploadService = FileUploadService();
  final TextEditingController _urlController = TextEditingController();

  String? _currentImageUrl;
  fps.PickedFile? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.initialImageUrl;
    _urlController.text = widget.initialImageUrl ?? '';
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Row(
            children: [
              Text(
                widget.label!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.required)
                const Text(
                  ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Image preview and picker
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image preview
            _buildImagePreview(),
            const SizedBox(width: 16),
            
            // Picker buttons
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.allowUpload) _buildPickerButtons(),
                  if (widget.showUrlInput) ...[
                    if (widget.allowUpload) const SizedBox(height: 12),
                    _buildUrlInput(),
                  ],
                ],
              ),
            ),
          ],
        ),

        // Upload progress
        if (_isUploading) ...[
          const SizedBox(height: 12),
          _buildUploadProgress(),
        ],
      ],
    );
  }

  Widget _buildImagePreview() {
    final size = widget.previewSize ?? 80;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: _currentImageUrl != null && _currentImageUrl!.isNotEmpty
            ? Image.network(
                _currentImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                    ),
                  );
                },
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(
        Icons.image,
        color: Colors.grey,
        size: 32,
      ),
    );
  }

  Widget _buildPickerButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isUploading ? null : () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('Gallery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isUploading ? null : () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Camera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isUploading ? null : _clearImage,
              icon: const Icon(Icons.clear),
              label: const Text('Clear'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUrlInput() {
    return TextField(
      controller: _urlController,
      decoration: InputDecoration(
        labelText: 'Or enter image URL',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.link),
        hintText: widget.hint ?? 'https://example.com/image.jpg',
        suffixIcon: _urlController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _urlController.clear();
                  _updateImageUrl('');
                },
                icon: const Icon(Icons.clear),
              )
            : null,
      ),
      onChanged: _updateImageUrl,
      enabled: !_isUploading,
    );
  }

  Widget _buildUploadProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.cloud_upload, size: 16, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              'Uploading... ${(_uploadProgress * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _uploadProgress,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _filePickerService.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (file != null) {
        setState(() {
          _selectedFile = file;
        });

        widget.onFileSelected?.call(file);

        // If upload is enabled, upload the file
        if (widget.allowUpload) {
          await _uploadFile(file);
        } else {
          // If upload is not enabled, just show the local file
          _updateImageUrl(file.path ?? '');
        }
      }
    } catch (e) {
      Logger.error('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadFile(fps.PickedFile file) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final result = await _uploadService.uploadImage(
        file,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      if (result.success && result.url != null) {
        _updateImageUrl(result.url!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(result.error ?? 'Upload failed');
      }
    } catch (e) {
      Logger.error('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  void _updateImageUrl(String url) {
    setState(() {
      _currentImageUrl = url;
      _urlController.text = url;
    });
    widget.onImageSelected(url);
  }

  void _clearImage() {
    setState(() {
      _currentImageUrl = null;
      _selectedFile = null;
      _urlController.clear();
    });
    widget.onImageSelected('');
  }

  /// Get current image URL
  String? get currentImageUrl => _currentImageUrl;

  /// Get selected file
  fps.PickedFile? get selectedFile => _selectedFile;

  /// Set image URL programmatically
  void setImageUrl(String? url) {
    setState(() {
      _currentImageUrl = url;
      _urlController.text = url ?? '';
    });
  }
}