import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../models/artifact.dart';
import 'api_service.dart';
import 'platform_config.dart';

/// Thrown when the scan backend returns 404 — "No matching artifact found."
class ScanNotFoundException implements Exception {
  final String message;
  final double similarity;
  ScanNotFoundException(this.message, this.similarity);
  @override
  String toString() => message;
}

class ScanService {
  static String get _scanUrl => '${getBaseUrl()}/ai/scan/';

  // Note: The backend also has /api/scan/ (via artifacts app).
  // Use the ai_services endpoint for the full AI pipeline.
  
  static final ImagePicker _picker = ImagePicker();

  /// Determine the MIME type from a filename extension.
  static MediaType _mediaTypeFromName(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'gif':
        return MediaType('image', 'gif');
      default:
        return MediaType('image', 'jpeg'); // Safe default for images
    }
  }

  static Future<XFile?> captureImage() async {
    return await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
  }

  static Future<XFile?> pickFromGallery() async {
    return await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
  }

  static Future<Artifact> scanWithImage(XFile imageFile) async {
    if (ApiService.useMockData) {
      await Future.delayed(const Duration(milliseconds: 2500));
      final artifacts = ApiService.mockArtifacts;
      final name = imageFile.name.toLowerCase();
      for (final artifact in artifacts) {
        final keywords = artifact.name.toLowerCase().split(' ');
        for (final kw in keywords) {
          if (kw.length > 3 && name.contains(kw)) return artifact;
        }
      }
      return artifacts[DateTime.now().millisecond % artifacts.length];
    }

    try {
      debugPrint('[ScanService] POST $_scanUrl');
      final request = http.MultipartRequest('POST', Uri.parse(_scanUrl));
      
      // Detect the correct MIME type from the file name
      final contentType = _mediaTypeFromName(imageFile.name);
      debugPrint('[ScanService] Detected content type: $contentType');
      
      // Web: use fromBytes (dart:io File not available)
      // Mobile: use fromPath (more efficient)
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: imageFile.name,
          contentType: contentType,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: contentType,
        ));
      }
      
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      
      debugPrint('[ScanService] Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return Artifact.fromScanJson(body);
        }
        throw Exception('Unexpected response format from scan service.');
      }

      // Handle 404 — "No matching artifact found"
      if (response.statusCode == 404) {
        final body = jsonDecode(response.body);
        final similarity = (body['similarity'] as num?)?.toDouble() ?? 0.0;
        final message = body['message']?.toString() ?? 'No matching artifact found';
        throw ScanNotFoundException(message, similarity);
      }
      
      // Try to parse error message from response body
      String errorMsg = '${response.statusCode} ${response.reasonPhrase}';
      try {
        final errorJson = jsonDecode(response.body);
        if (errorJson is Map) {
          if (errorJson['error'] != null) {
            errorMsg = errorJson['error'].toString();
          } else if (errorJson['message'] != null) {
            errorMsg = errorJson['message'].toString();
          }
        }
      } catch (_) {
        // body wasn't JSON, use status code message
      }
      throw errorMsg;
    } catch (e) {
      debugPrint('[ScanService] Error: $e');
      // Re-throw ScanNotFoundException as-is
      if (e is ScanNotFoundException) rethrow;
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('XMLHttpRequest')) {
        throw Exception('Network error: Unable to reach the AI scan service. Please check your connection.');
      }
      rethrow;
    }
  }

  static Future<Artifact> scanMockDemo() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    return ApiService.mockArtifacts[DateTime.now().second % ApiService.mockArtifacts.length];
  }
}
