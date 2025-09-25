import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/app_config.dart';
import '../utils/storage_helper.dart';

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
      );

      if (image != null) {
        return File(image.path);
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

      return limitedImages.map((image) => File(image.path)).toList();
    } catch (e) {
      throw Exception('Failed to pick images: $e');
    }
  }

  // Upload profile picture
  static Future<String> uploadProfilePicture({
    required File imageFile,
  }) async {
    try {
      final token = await StorageHelper.getAccessToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/uploads/profile-picture');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath('profile_picture', imageFile.path),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = 
            Map<String, dynamic>.from(json.decode(responseBody));
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

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/uploads/tour-image');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add files and fields
      request.files.add(
        await http.MultipartFile.fromPath('tour_image', imageFile.path),
      );
      request.fields['image_type'] = imageType;

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = 
            Map<String, dynamic>.from(json.decode(responseBody));
        return data['fileUrl'] as String;
      } else {
        throw Exception('Upload failed: $responseBody');
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

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/uploads/multiple-tour-images');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add multiple files
      for (int i = 0; i < imageFiles.length; i++) {
        request.files.add(
          await http.MultipartFile.fromPath('tour_images', imageFiles[i].path),
        );
      }
      request.fields['image_type'] = imageType;

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = 
            Map<String, dynamic>.from(json.decode(responseBody));
        final List<dynamic> urls = data['fileUrls'] as List<dynamic>;
        return urls.cast<String>();
      } else {
        throw Exception('Upload failed: $responseBody');
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
        Uri.parse('${AppConfig.apiBaseUrl}/uploads/presigned-url'),
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
        headers: {
          'Content-Type': contentType,
        },
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