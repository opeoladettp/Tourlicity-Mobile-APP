import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';

class FilePickerService {
  static final FilePickerService _instance = FilePickerService._internal();
  factory FilePickerService() => _instance;
  FilePickerService._internal();

  final ImagePicker _imagePicker = ImagePicker();

  /// Pick a single image from gallery or camera
  Future<PickedFile?> pickImage({
    ImageSource source = ImageSource.gallery,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    try {
      Logger.info('📸 Picking image from ${source.name}');
      
      // Request permissions
      if (source == ImageSource.camera) {
        final cameraPermission = await _requestCameraPermission();
        if (!cameraPermission) {
          throw Exception('Camera permission denied');
        }
      } else {
        final storagePermission = await _requestStoragePermission();
        if (!storagePermission) {
          throw Exception('Storage permission denied');
        }
      }

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
      );

      if (image != null) {
        Logger.info('✅ Image picked successfully: ${image.name}');
        return PickedFile(
          path: image.path,
          name: image.name,
          size: await image.length(),
          type: FileType.image,
          bytes: kIsWeb ? await image.readAsBytes() : null,
        );
      }

      Logger.info('❌ No image selected');
      return null;
    } catch (e) {
      Logger.error('❌ Error picking image: $e');
      rethrow;
    }
  }

  /// Pick multiple images from gallery
  Future<List<PickedFile>> pickMultipleImages({
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
    int? limit,
  }) async {
    try {
      Logger.info('📸 Picking multiple images');
      
      final storagePermission = await _requestStoragePermission();
      if (!storagePermission) {
        throw Exception('Storage permission denied');
      }

      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
        limit: limit,
      );

      final List<PickedFile> pickedFiles = [];
      for (final image in images) {
        pickedFiles.add(PickedFile(
          path: image.path,
          name: image.name,
          size: await image.length(),
          type: FileType.image,
          bytes: kIsWeb ? await image.readAsBytes() : null,
        ));
      }

      Logger.info('✅ ${pickedFiles.length} images picked successfully');
      return pickedFiles;
    } catch (e) {
      Logger.error('❌ Error picking multiple images: $e');
      rethrow;
    }
  }

  /// Pick any type of file
  Future<PickedFile?> pickFile({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
    bool withData = false,
  }) async {
    try {
      Logger.info('📁 Picking file of type: ${type.name}');
      
      final storagePermission = await _requestStoragePermission();
      if (!storagePermission) {
        throw Exception('Storage permission denied');
      }

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
        withData: withData,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        Logger.info('✅ File picked successfully: ${file.name}');
        
        return PickedFile(
          path: file.path,
          name: file.name,
          size: file.size,
          type: type,
          bytes: file.bytes,
          extension: file.extension,
        );
      }

      Logger.info('❌ No file selected');
      return null;
    } catch (e) {
      Logger.error('❌ Error picking file: $e');
      rethrow;
    }
  }

  /// Pick multiple files
  Future<List<PickedFile>> pickMultipleFiles({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool withData = false,
  }) async {
    try {
      Logger.info('📁 Picking multiple files of type: ${type.name}');
      
      final storagePermission = await _requestStoragePermission();
      if (!storagePermission) {
        throw Exception('Storage permission denied');
      }

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
        withData: withData,
      );

      if (result != null && result.files.isNotEmpty) {
        final List<PickedFile> pickedFiles = result.files.map((file) {
          return PickedFile(
            path: file.path,
            name: file.name,
            size: file.size,
            type: type,
            bytes: file.bytes,
            extension: file.extension,
          );
        }).toList();

        Logger.info('✅ ${pickedFiles.length} files picked successfully');
        return pickedFiles;
      }

      Logger.info('❌ No files selected');
      return [];
    } catch (e) {
      Logger.error('❌ Error picking multiple files: $e');
      rethrow;
    }
  }

  /// Pick documents (PDF, DOC, DOCX, TXT, etc.)
  Future<PickedFile?> pickDocument() async {
    return await pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'rtf', 'odt'],
    );
  }

  /// Pick media files (images and videos)
  Future<PickedFile?> pickMedia() async {
    return await pickFile(type: FileType.media);
  }

  /// Pick video file
  Future<PickedFile?> pickVideo() async {
    return await pickFile(type: FileType.video);
  }

  /// Pick audio file
  Future<PickedFile?> pickAudio() async {
    return await pickFile(type: FileType.audio);
  }

  /// Request camera permission
  Future<bool> _requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      Logger.error('❌ Error requesting camera permission: $e');
      return false;
    }
  }

  /// Request storage permission
  Future<bool> _requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        // For Android 13+ (API 33+), we need different permissions
        final androidInfo = await _getAndroidVersion();
        if (androidInfo >= 33) {
          final photos = await Permission.photos.request();
          final videos = await Permission.videos.request();
          return photos.isGranted && videos.isGranted;
        } else {
          final storage = await Permission.storage.request();
          return storage.isGranted;
        }
      } else if (Platform.isIOS) {
        final photos = await Permission.photos.request();
        return photos.isGranted;
      }
      return true; // For web and other platforms
    } catch (e) {
      Logger.error('❌ Error requesting storage permission: $e');
      return false;
    }
  }

  /// Get Android SDK version
  Future<int> _getAndroidVersion() async {
    try {
      // This is a simplified version - in a real app you might want to use
      // device_info_plus package for more accurate version detection
      return 33; // Assume modern Android for now
    } catch (e) {
      return 30; // Fallback to older Android
    }
  }

  /// Check if file is an image
  static bool isImage(String? extension) {
    if (extension == null) return false;
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'];
    return imageExtensions.contains(extension.toLowerCase());
  }

  /// Check if file is a video
  static bool isVideo(String? extension) {
    if (extension == null) return false;
    const videoExtensions = ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm', 'mkv'];
    return videoExtensions.contains(extension.toLowerCase());
  }

  /// Check if file is a document
  static bool isDocument(String? extension) {
    if (extension == null) return false;
    const docExtensions = ['pdf', 'doc', 'docx', 'txt', 'rtf', 'odt', 'xls', 'xlsx', 'ppt', 'pptx'];
    return docExtensions.contains(extension.toLowerCase());
  }

  /// Get file size in human readable format
  static String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Represents a picked file with all necessary information
class PickedFile {
  final String? path;
  final String name;
  final int size;
  final FileType type;
  final Uint8List? bytes;
  final String? extension;

  PickedFile({
    this.path,
    required this.name,
    required this.size,
    required this.type,
    this.bytes,
    this.extension,
  });

  /// Get file as File object (for mobile platforms)
  File? get file => path != null ? File(path!) : null;

  /// Check if this is an image file
  bool get isImage => FilePickerService.isImage(extension);

  /// Check if this is a video file
  bool get isVideo => FilePickerService.isVideo(extension);

  /// Check if this is a document file
  bool get isDocument => FilePickerService.isDocument(extension);

  /// Get human readable file size
  String get sizeString => FilePickerService.getFileSizeString(size);

  /// Get file icon based on type
  String get iconName {
    if (isImage) return 'image';
    if (isVideo) return 'video';
    if (isDocument) return 'document';
    return 'file';
  }

  @override
  String toString() {
    return 'PickedFile(name: $name, size: $sizeString, type: ${type.name}, extension: $extension)';
  }
}