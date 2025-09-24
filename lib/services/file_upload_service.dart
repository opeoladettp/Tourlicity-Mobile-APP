import 'dart:io';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/file_picker_service.dart';
import '../config/app_config.dart';
import '../utils/logger.dart';

class FileUploadService {
  final ApiService _apiService = ApiService();
  late final Dio _dio;

  FileUploadService() {
    _dio = Dio(BaseOptions(
      baseUrl: '${AppConfig.apiBaseUrl}/api',
      connectTimeout: AppConfig.apiTimeout,
      receiveTimeout: AppConfig.apiTimeout,
      sendTimeout: AppConfig.apiTimeout,
    ));
    
    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _apiService.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  /// Upload a single file
  Future<UploadResult> uploadFile(
    PickedFile file, {
    String? uploadPath,
    Map<String, dynamic>? additionalData,
    Function(double)? onProgress,
  }) async {
    try {
      Logger.info('📤 Starting file upload: ${file.name}');

      // Prepare form data
      final formData = FormData();
      
      if (file.bytes != null) {
        // For web or when bytes are available
        formData.files.add(MapEntry(
          'file',
          MultipartFile.fromBytes(
            file.bytes!,
            filename: file.name,
          ),
        ));
      } else if (file.path != null) {
        // For mobile platforms
        formData.files.add(MapEntry(
          'file',
          await MultipartFile.fromFile(
            file.path!,
            filename: file.name,
          ),
        ));
      } else {
        throw Exception('No file data available for upload');
      }

      // Add additional data if provided
      if (additionalData != null) {
        additionalData.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });
      }

      // Determine upload endpoint
      final endpoint = uploadPath ?? '/upload';

      // Upload file with progress tracking
      final response = await _dio.post(
        endpoint,
        data: formData,
        onSendProgress: onProgress != null
            ? (sent, total) {
                final progress = sent / total;
                onProgress(progress);
              }
            : null,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Logger.info('✅ File uploaded successfully: ${file.name}');
        return UploadResult(
          success: true,
          url: response.data['url'] ?? response.data['file_url'],
          fileName: response.data['filename'] ?? file.name,
          fileSize: response.data['size'] ?? file.size,
          message: response.data['message'] ?? 'File uploaded successfully',
        );
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('❌ File upload failed: $e');
      return UploadResult(
        success: false,
        error: e.toString(),
        message: 'Failed to upload file: ${e.toString()}',
      );
    }
  }

  /// Upload multiple files
  Future<List<UploadResult>> uploadMultipleFiles(
    List<PickedFile> files, {
    String? uploadPath,
    Map<String, dynamic>? additionalData,
    Function(int, double)? onProgress,
  }) async {
    final results = <UploadResult>[];
    
    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      
      final result = await uploadFile(
        file,
        uploadPath: uploadPath,
        additionalData: additionalData,
        onProgress: onProgress != null
            ? (progress) => onProgress(i, progress)
            : null,
      );
      
      results.add(result);
    }
    
    return results;
  }

  /// Upload image with specific endpoint
  Future<UploadResult> uploadImage(
    PickedFile image, {
    Function(double)? onProgress,
  }) async {
    return await uploadFile(
      image,
      uploadPath: '/upload/image',
      onProgress: onProgress,
    );
  }

  /// Upload document with specific endpoint
  Future<UploadResult> uploadDocument(
    PickedFile document, {
    Function(double)? onProgress,
  }) async {
    return await uploadFile(
      document,
      uploadPath: '/upload/document',
      onProgress: onProgress,
    );
  }

  /// Upload profile picture
  Future<UploadResult> uploadProfilePicture(
    PickedFile image, {
    Function(double)? onProgress,
  }) async {
    return await uploadFile(
      image,
      uploadPath: '/upload/profile-picture',
      onProgress: onProgress,
    );
  }

  /// Upload tour template featured image
  Future<UploadResult> uploadTourTemplateImage(
    PickedFile image,
    String templateId, {
    Function(double)? onProgress,
  }) async {
    return await uploadFile(
      image,
      uploadPath: '/upload/tour-template/$templateId/image',
      onProgress: onProgress,
    );
  }

  /// Upload calendar entry featured image
  Future<UploadResult> uploadCalendarImage(
    PickedFile image,
    String calendarEntryId, {
    Function(double)? onProgress,
  }) async {
    return await uploadFile(
      image,
      uploadPath: '/calendar/$calendarEntryId/featured-image',
      onProgress: onProgress,
    );
  }

  /// Get presigned URL for direct upload (for large files)
  Future<PresignedUploadResult> getPresignedUploadUrl({
    required String fileName,
    required String contentType,
    String? folder,
  }) async {
    try {
      Logger.info('🔗 Getting presigned URL for: $fileName');

      final response = await _apiService.post(
        '/upload/presigned-url',
        data: {
          'fileName': fileName,
          'contentType': contentType,
          if (folder != null) 'folder': folder,
        },
      );

      if (response.statusCode == 200) {
        Logger.info('✅ Presigned URL obtained successfully');
        return PresignedUploadResult(
          success: true,
          presignedUrl: response.data['presignedUrl'],
          publicUrl: response.data['publicUrl'],
          key: response.data['key'],
          expiresIn: response.data['expiresIn'],
        );
      } else {
        throw Exception('Failed to get presigned URL: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('❌ Failed to get presigned URL: $e');
      return PresignedUploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Upload file using presigned URL
  Future<bool> uploadWithPresignedUrl(
    String presignedUrl,
    PickedFile file, {
    Function(double)? onProgress,
  }) async {
    try {
      Logger.info('📤 Uploading with presigned URL: ${file.name}');

      final dio = Dio();
      
      dynamic data;
      if (file.bytes != null) {
        data = file.bytes;
      } else if (file.path != null) {
        data = File(file.path!).openRead();
      } else {
        throw Exception('No file data available for upload');
      }

      final response = await dio.put(
        presignedUrl,
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/octet-stream',
          },
        ),
        onSendProgress: onProgress != null
            ? (sent, total) {
                final progress = sent / total;
                onProgress(progress);
              }
            : null,
      );

      if (response.statusCode == 200) {
        Logger.info('✅ File uploaded successfully with presigned URL');
        return true;
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('❌ Presigned URL upload failed: $e');
      return false;
    }
  }

  /// Validate file before upload
  bool validateFile(PickedFile file, {
    int? maxSizeBytes,
    List<String>? allowedExtensions,
  }) {
    // Check file size
    if (maxSizeBytes != null && file.size > maxSizeBytes) {
      Logger.warning('File too large: ${file.sizeString} > ${FilePickerService.getFileSizeString(maxSizeBytes)}');
      return false;
    }

    // Check file extension
    if (allowedExtensions != null && file.extension != null) {
      if (!allowedExtensions.contains(file.extension!.toLowerCase())) {
        Logger.warning('File extension not allowed: ${file.extension}');
        return false;
      }
    }

    return true;
  }
}

/// Result of a file upload operation
class UploadResult {
  final bool success;
  final String? url;
  final String? fileName;
  final int? fileSize;
  final String? error;
  final String message;

  UploadResult({
    required this.success,
    this.url,
    this.fileName,
    this.fileSize,
    this.error,
    required this.message,
  });

  @override
  String toString() {
    return 'UploadResult(success: $success, url: $url, fileName: $fileName, message: $message)';
  }
}

/// Result of getting a presigned upload URL
class PresignedUploadResult {
  final bool success;
  final String? presignedUrl;
  final String? publicUrl;
  final String? key;
  final int? expiresIn;
  final String? error;

  PresignedUploadResult({
    required this.success,
    this.presignedUrl,
    this.publicUrl,
    this.key,
    this.expiresIn,
    this.error,
  });

  @override
  String toString() {
    return 'PresignedUploadResult(success: $success, publicUrl: $publicUrl, expiresIn: $expiresIn)';
  }
}