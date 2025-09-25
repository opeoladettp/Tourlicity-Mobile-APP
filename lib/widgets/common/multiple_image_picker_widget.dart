import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/image_upload_service.dart';

class MultipleImagePickerWidget extends StatefulWidget {
  final List<String> initialImageUrls;
  final Function(List<String>) onImagesChanged;
  final String imageType;
  final String label;
  final int maxImages;
  final bool isRequired;

  const MultipleImagePickerWidget({
    super.key,
    this.initialImageUrls = const [],
    required this.onImagesChanged,
    required this.imageType,
    required this.label,
    this.maxImages = 5,
    this.isRequired = false,
  });

  @override
  State<MultipleImagePickerWidget> createState() =>
      _MultipleImagePickerWidgetState();
}

class _MultipleImagePickerWidgetState extends State<MultipleImagePickerWidget> {
  List<String> _imageUrls = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _imageUrls = List.from(widget.initialImageUrls);
  }

  Future<void> _pickImages() async {
    if (_imageUrls.length >= widget.maxImages) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maximum ${widget.maxImages} images allowed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      setState(() {
        _isUploading = true;
      });

      final int remainingSlots = widget.maxImages - _imageUrls.length;
      final List<File> files = await ImageUploadService.pickMultipleImages(
        limit: remainingSlots,
      );

      if (files.isNotEmpty) {
        final List<String> uploadedUrls =
            await ImageUploadService.uploadMultipleTourImages(
              imageFiles: files,
              imageType: widget.imageType,
            );

        setState(() {
          _imageUrls.addAll(uploadedUrls);
          _isUploading = false;
        });

        widget.onImagesChanged(_imageUrls);
      } else {
        setState(() {
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
    widget.onImagesChanged(_imageUrls);
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final String item = _imageUrls.removeAt(oldIndex);
      _imageUrls.insert(newIndex, item);
    });
    widget.onImagesChanged(_imageUrls);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (widget.isRequired)
                  const Text(' *', style: TextStyle(color: Colors.red)),
              ],
            ),
            Text(
              '${_imageUrls.length}/${widget.maxImages}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_imageUrls.isEmpty && !_isUploading)
          _buildEmptyState()
        else
          _buildImageGrid(),
        const SizedBox(height: 12),
        if (_imageUrls.length < widget.maxImages)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickImages,
              icon: _isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_photo_alternate),
              label: Text(_isUploading ? 'Uploading...' : 'Add Images'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
          width: 2,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 32,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'No ${widget.label.toLowerCase()} added yet',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onReorder: _reorderImages,
      itemCount: _imageUrls.length,
      itemBuilder: (context, index) {
        return _buildImageItem(index);
      },
    );
  }

  Widget _buildImageItem(int index) {
    return Container(
      key: ValueKey(_imageUrls[index]),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Drag handle
          const Icon(Icons.drag_handle, color: Colors.grey),
          const SizedBox(width: 8),
          // Image thumbnail
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.network(
                _imageUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Image info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Image ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  _imageUrls[index].split('/').last,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Remove button
          IconButton(
            onPressed: () => _removeImage(index),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Remove image',
          ),
        ],
      ),
    );
  }
}
