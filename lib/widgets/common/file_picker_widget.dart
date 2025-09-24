import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/file_picker_service.dart' as fps;
import '../../utils/logger.dart';

class FilePickerWidget extends StatefulWidget {
  final Function(fps.PickedFile) onFilePicked;
  final Function(List<fps.PickedFile>)? onMultipleFilesPicked;
  final FileType fileType;
  final List<String>? allowedExtensions;
  final bool allowMultiple;
  final bool showPreview;
  final String? label;
  final String? hint;
  final Widget? icon;
  final bool required;

  const FilePickerWidget({
    super.key,
    required this.onFilePicked,
    this.onMultipleFilesPicked,
    this.fileType = FileType.any,
    this.allowedExtensions,
    this.allowMultiple = false,
    this.showPreview = true,
    this.label,
    this.hint,
    this.icon,
    this.required = false,
  });

  @override
  State<FilePickerWidget> createState() => _FilePickerWidgetState();
}

class _FilePickerWidgetState extends State<FilePickerWidget> {
  final fps.FilePickerService _filePickerService = fps.FilePickerService();

  List<fps.PickedFile> _selectedFiles = [];
  bool _isLoading = false;

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
                const Text(' *', style: TextStyle(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // File picker button
        InkWell(
          onTap: _isLoading ? null : _pickFile,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: _isLoading ? Colors.grey[100] : null,
            ),
            child: _isLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Selecting file...'),
                    ],
                  )
                : Row(
                    children: [
                      widget.icon ?? _getDefaultIcon(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFiles.isEmpty
                                  ? (widget.hint ?? _getDefaultHint())
                                  : widget.allowMultiple
                                  ? '${_selectedFiles.length} file(s) selected'
                                  : _selectedFiles.first.name,
                              style: TextStyle(
                                color: _selectedFiles.isEmpty
                                    ? Colors.grey[600]
                                    : Colors.black87,
                                fontWeight: _selectedFiles.isEmpty
                                    ? FontWeight.normal
                                    : FontWeight.w500,
                              ),
                            ),
                            if (_selectedFiles.isNotEmpty &&
                                !widget.allowMultiple)
                              Text(
                                _selectedFiles.first.sizeString,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(Icons.upload_file, color: Colors.grey[600]),
                    ],
                  ),
          ),
        ),

        // File preview
        if (widget.showPreview && _selectedFiles.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildFilePreview(),
        ],
      ],
    );
  }

  Widget _getDefaultIcon() {
    switch (widget.fileType) {
      case FileType.image:
        return const Icon(Icons.image, color: Colors.blue);
      case FileType.video:
        return const Icon(Icons.video_file, color: Colors.red);
      case FileType.audio:
        return const Icon(Icons.audio_file, color: Colors.green);
      case FileType.custom:
        if (widget.allowedExtensions?.any(
              (ext) => ['pdf', 'doc', 'docx'].contains(ext),
            ) ==
            true) {
          return const Icon(Icons.description, color: Colors.orange);
        }
        return const Icon(Icons.insert_drive_file, color: Colors.grey);
      default:
        return const Icon(Icons.attach_file, color: Colors.grey);
    }
  }

  String _getDefaultHint() {
    switch (widget.fileType) {
      case FileType.image:
        return widget.allowMultiple ? 'Select images' : 'Select an image';
      case FileType.video:
        return widget.allowMultiple ? 'Select videos' : 'Select a video';
      case FileType.audio:
        return widget.allowMultiple
            ? 'Select audio files'
            : 'Select an audio file';
      case FileType.custom:
        if (widget.allowedExtensions?.any(
              (ext) => ['pdf', 'doc', 'docx'].contains(ext),
            ) ==
            true) {
          return widget.allowMultiple
              ? 'Select documents'
              : 'Select a document';
        }
        return widget.allowMultiple ? 'Select files' : 'Select a file';
      default:
        return widget.allowMultiple ? 'Select files' : 'Select a file';
    }
  }

  Future<void> _pickFile() async {
    setState(() => _isLoading = true);

    try {
      if (widget.fileType == FileType.image && !widget.allowMultiple) {
        // Show image source selection for single images
        await _showImageSourceDialog();
      } else if (widget.allowMultiple) {
        final files = await _filePickerService.pickMultipleFiles(
          type: widget.fileType,
          allowedExtensions: widget.allowedExtensions,
          withData: true,
        );

        if (files.isNotEmpty) {
          setState(() => _selectedFiles = files);
          widget.onMultipleFilesPicked?.call(files);
        }
      } else {
        final file = await _filePickerService.pickFile(
          type: widget.fileType,
          allowedExtensions: widget.allowedExtensions,
          withData: true,
        );

        if (file != null) {
          setState(() => _selectedFiles = [file]);
          widget.onFilePicked(file);
        }
      }
    } catch (e) {
      Logger.error('Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showImageSourceDialog() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (source != null) {
      final file = await _filePickerService.pickImage(source: source);
      if (file != null) {
        setState(() => _selectedFiles = [file]);
        widget.onFilePicked(file);
      }
    }
  }

  Widget _buildFilePreview() {
    if (widget.allowMultiple) {
      return _buildMultipleFilePreview();
    } else {
      return _buildSingleFilePreview(_selectedFiles.first);
    }
  }

  Widget _buildSingleFilePreview(fps.PickedFile file) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          _buildFileIcon(file),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  file.sizeString,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() => _selectedFiles.clear());
            },
            icon: const Icon(Icons.close, size: 20),
            tooltip: 'Remove file',
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleFilePreview() {
    return Column(
      children: _selectedFiles.map((file) {
        final index = _selectedFiles.indexOf(file);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              _buildFileIcon(file),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      file.sizeString,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() => _selectedFiles.removeAt(index));
                  if (widget.onMultipleFilesPicked != null) {
                    widget.onMultipleFilesPicked!(_selectedFiles);
                  }
                },
                icon: const Icon(Icons.close, size: 20),
                tooltip: 'Remove file',
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFileIcon(fps.PickedFile file) {
    if (file.isImage && file.bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.memory(
          file.bytes!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _getFileTypeIcon(file);
          },
        ),
      );
    }

    return _getFileTypeIcon(file);
  }

  Widget _getFileTypeIcon(fps.PickedFile file) {
    IconData iconData;
    Color color;

    if (file.isImage) {
      iconData = Icons.image;
      color = Colors.blue;
    } else if (file.isVideo) {
      iconData = Icons.video_file;
      color = Colors.red;
    } else if (file.isDocument) {
      iconData = Icons.description;
      color = Colors.orange;
    } else {
      iconData = Icons.insert_drive_file;
      color = Colors.grey;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(iconData, color: color, size: 24),
    );
  }

  /// Clear selected files
  void clearFiles() {
    setState(() => _selectedFiles.clear());
  }

  /// Get selected files
  List<fps.PickedFile> get selectedFiles => _selectedFiles;
}
