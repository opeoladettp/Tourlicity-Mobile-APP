import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/app_config.dart';
import '../utils/storage_helper.dart';
import '../utils/logger.dart';

class ImageUploadService {
  static final ImagePicker _picker = ImagePicker();

  // Pick image from gallery or camera
  static Future<File?> pickImage({
    required ImageSource source,
    int? imageQuality = 85,
  }) async {
    try {
      // Request permissions
      if (source == ImageSource.camera) {
        final cameraStatus = await Permission.camera.request();
        if (!cameraStatus.isGranted) {
          throw Exception('Camera permission denied');
        }
      } else {
        final storageStatus = await Permission.photos.request();
        if (!storageStatus.isGranted) {
          throw Exception('Storage permission denied');
        }
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: 1920,
        maxHeight: 1080,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        final file = File(image.path);
        final extension = file.path.split('.').last.toLowerCase();

        // Validate file extension
        if (!['jpg', 'jpeg', 'png'].contains(extension)) {
          throw Exception(
            'Unsupported file format. Please select a JPEG or PNG image.',
          );
        }

        return file;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  // Pick multiple images from gallery
  static Future<List<File>> pickMultipleImages({
    int? imageQuality = 85,
    int? limit = 5,
  }) async {
    try {
      final storageStatus = await Permission.photos.request();
      if (!storageStatus.isGranted) {
        throw Exception('Storage permission denied');
      }

      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: imageQuality,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      // Limit the number of images
      final limitedImages = limit != null && images.length > limit
          ? images.take(limit).toList()
          : images;

      // Validate and convert to files
      final validFiles = <File>[];
      for (final image in limitedImages) {
        final file = File(image.path);
        final extension = file.path.split('.').last.toLowerCase();

        // Only include supported formats
        if (['jpg', 'jpeg', 'png'].contains(extension)) {
          validFiles.add(file);
        }
      }

      if (validFiles.isEmpty && limitedImages.isNotEmpty) {
        throw Exception(
          'No supported image formats found. Please select JPEG or PNG images.',
        );
      }

      return validFiles;
    } catch (e) {
      throw Exception('Failed to pick images: $e');
    }
  }

  // Upload profile picture
  static Future<String> uploadProfilePicture({required File imageFile}) async {
    try {
      final token = await StorageHelper.getAccessToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final uri = Uri.parse(
        '${AppConfig.apiBaseUrl}/api/uploads/profile-picture',
      );
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add file with explicit MIME type
      final extension = imageFile.path.split('.').last.toLowerCase();
      final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';

      request.files.add(
        http.MultipartFile.fromBytes(
          'profile_picture',
          await imageFile.readAsBytes(),
          filename: imageFile.path.split('/').last,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          json.decode(responseBody),
        );
        return data['fileUrl'] as String;
      } else {
        throw Exception('Upload failed: $responseBody');
      }
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  // Upload single tour image
  static Future<String> uploadTourImage({
    required File imageFile,
    required String imageType, // 'features' or 'teaser'
  }) async {
    try {
      final token = await StorageHelper.getAccessToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/uploads/tour-image');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add files and fields with explicit MIME type
      final extension = imageFile.path.split('.').last.toLowerCase();
      final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';

      request.files.add(
        http.MultipartFile.fromBytes(
          'tour_image',
          await imageFile.readAsBytes(),
          filename: imageFile.path.split('/').last,
          contentType: MediaType.parse(mimeType),
        ),
      );
      request.fields['image_type'] = imageType;

      Logger.info('🔄 Uploading tour image to: ${uri.toString()}');
      Logger.info('📤 Image type: $imageType');
      Logger.info('📄 File path: ${imageFile.path}');
      Logger.info('📄 File name: ${imageFile.path.split('/').last}');
      Logger.info('📄 File extension: $extension');
      Logger.info('🎯 Setting MIME type: $mimeType');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      Logger.info('📥 Upload response status: ${response.statusCode}');
      Logger.info('📋 Upload response body: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          json.decode(responseBody),
        );
        final fileUrl = data['fileUrl'] as String;
        Logger.info('✅ Image uploaded successfully: $fileUrl');
        return fileUrl;
      } else {
        Logger.error(
          '❌ Upload failed with status ${response.statusCode}: $responseBody',
        );
        throw Exception(
          'Upload failed (${response.statusCode}): $responseBody',
        );
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Upload multiple tour images
  static Future<List<String>> uploadMultipleTourImages({
    required List<File> imageFiles,
    required String imageType,
  }) async {
    try {
      final token = await StorageHelper.getAccessToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final uri = Uri.parse(
        '${AppConfig.apiBaseUrl}/api/uploads/multiple-tour-images',
      );
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add multiple files with explicit MIME type
      for (int i = 0; i < imageFiles.length; i++) {
        final extension = imageFiles[i].path.split('.').last.toLowerCase();
        final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';

        request.files.add(
          http.MultipartFile.fromBytes(
            'tour_images',
            await imageFiles[i].readAsBytes(),
            filename: imageFiles[i].path.split('/').last,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }
      request.fields['image_type'] = imageType;

      Logger.info(
        '🔄 Uploading ${imageFiles.length} images to: ${uri.toString()}',
      );
      Logger.info('📤 Image type: $imageType');
      for (int i = 0; i < imageFiles.length; i++) {
        Logger.info('📄 File ${i + 1}: ${imageFiles[i].path}');
        Logger.info(
          '📄 File ${i + 1} name: ${imageFiles[i].path.split('/').last}',
        );
        Logger.info(
          '📄 File ${i + 1} extension: ${imageFiles[i].path.split('.').last.toLowerCase()}',
        );
        final extension = imageFiles[i].path.split('.').last.toLowerCase();
        final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
        Logger.info('🎯 File ${i + 1} MIME type: $mimeType');
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      Logger.info('📥 Multiple upload response status: ${response.statusCode}');
      Logger.info('📋 Multiple upload response body: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          json.decode(responseBody),
        );
        final List<dynamic> urls = data['fileUrls'] as List<dynamic>;
        Logger.info('✅ ${urls.length} images uploaded successfully');
        return urls.cast<String>();
      } else {
        Logger.error(
          '❌ Multiple upload failed with status ${response.statusCode}: $responseBody',
        );
        throw Exception(
          'Upload failed (${response.statusCode}): $responseBody',
        );
      }
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }

  // Get presigned URL for direct S3 upload (for large files)
  static Future<Map<String, String>> getPresignedUrl({
    required String fileName,
    required String contentType,
    String fileType = 'general',
  }) async {
    try {
      final token = await StorageHelper.getAccessToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/uploads/presigned-url'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'fileName': fileName,
          'fileType': fileType,
          'contentType': contentType,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'presignedUrl': data['presignedUrl'] as String,
          'publicUrl': data['publicUrl'] as String,
          'key': data['key'] as String,
        };
      } else {
        throw Exception('Failed to get presigned URL: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get presigned URL: $e');
    }
  }

  // Upload file directly to S3 using presigned URL
  static Future<String> uploadToS3({
    required File file,
    required String presignedUrl,
    required String contentType,
  }) async {
    try {
      final bytes = await file.readAsBytes();

      final response = await http.put(
        Uri.parse(presignedUrl),
        headers: {'Content-Type': contentType},
        body: bytes,
      );

      if (response.statusCode == 200) {
        // Extract public URL from presigned URL
        final uri = Uri.parse(presignedUrl);
        return '${uri.scheme}://${uri.host}${uri.path}';
      } else {
        throw Exception('S3 upload failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to upload to S3: $e');
    }
  }
}
