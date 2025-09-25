import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/image_upload_service.dart';

class ImagePickerWidget extends StatefulWidget {
  final String? initialImageUrl;
  final Function(String?) onImageSelected;
  final String? imageType; // 'features', 'teaser', or 'profile'
  final String? label;
  final bool isRequired;
  final double? height;
  final double? width;
  final String? hint;
  final double? previewSize;
  final bool allowUpload;
  final bool showUrlInput;

  const ImagePickerWidget({
    super.key,
    this.initialImageUrl,
    required this.onImageSelected,
    this.imageType = 'general',
    this.label,
    this.isRequired = false,
    this.height = 200,
    this.width = double.infinity,
    this.hint,
    this.previewSize,
    this.allowUpload = true,
    this.showUrlInput = true,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  String? _imageUrl;
  File? _selectedFile;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.initialImageUrl;
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_imageUrl != null || _selectedFile != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Image'),
                  onTap: () {
                    Navigator.pop(context);
                    _removeImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final File? file = await ImageUploadService.pickImage(source: source);
      if (file != null) {
        setState(() {
          _selectedFile = file;
          _imageUrl = null; // Clear URL when new file is selected
          _isUploading = true;
        });

        // Upload the image based on type
        String uploadedUrl;
        if (widget.imageType == 'profile') {
          uploadedUrl = await ImageUploadService.uploadProfilePicture(
            imageFile: file,
          );
        } else {
          uploadedUrl = await ImageUploadService.uploadTourImage(
            imageFile: file,
            imageType: widget.imageType ?? 'general',
          );
        }

        setState(() {
          _imageUrl = uploadedUrl;
          _isUploading = false;
        });

        widget.onImageSelected(uploadedUrl);
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _imageUrl = null;
      _selectedFile = null;
    });
    widget.onImageSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    // For profile pictures, use circular layout
    if (widget.previewSize != null) {
      return _buildProfilePictureLayout();
    }

    // Default rectangular layout for tour images
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
              if (widget.isRequired)
                const Text(
                  ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          onTap: _isUploading ? null : _showImageSourceDialog,
          child: Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade300,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildImageContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePictureLayout() {
    return Column(
      children: [
        GestureDetector(
          onTap: _isUploading ? null : _showImageSourceDialog,
          child: Container(
            width: widget.previewSize,
            height: widget.previewSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey.shade300,
                width: 3,
              ),
            ),
            child: _buildCircularImageContent(),
          ),
        ),
        if (widget.hint != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.hint!,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildImageContent() {
    if (_isUploading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('Uploading...'),
          ],
        ),
      );
    }

    if (_selectedFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          _selectedFile!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }

    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          _imageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
        ),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildCircularImageContent() {
    if (_isUploading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_selectedFile != null) {
      return ClipOval(
        child: Image.file(
          _selectedFile!,
          fit: BoxFit.cover,
          width: widget.previewSize,
          height: widget.previewSize,
        ),
      );
    }

    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          _imageUrl!,
          fit: BoxFit.cover,
          width: widget.previewSize,
          height: widget.previewSize,
          errorBuilder: (context, error, stackTrace) {
            return _buildCircularPlaceholder();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
        ),
      );
    }

    return _buildCircularPlaceholder();
  }

  Widget _buildCircularPlaceholder() {
    return Container(
      width: widget.previewSize,
      height: widget.previewSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade100,
      ),
      child: Icon(
        Icons.person,
        size: (widget.previewSize ?? 120) * 0.5,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate,
          size: 48,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 8),
        Text(
          widget.label != null 
              ? 'Tap to add ${widget.label!.toLowerCase()}'
              : 'Tap to add image',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}