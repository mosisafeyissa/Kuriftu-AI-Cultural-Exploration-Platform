import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../models/artifact.dart';
import 'api_service.dart';
import 'platform_config.dart';

class ScanService {
  static String get _scanUrl => '${getBaseUrl()}/ai/scan/';

  // Note: The backend also has /api/scan/ (via artifacts app).
  // Use the ai_services endpoint for the full AI pipeline.
  
  static final ImagePicker _picker = ImagePicker();

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
      request.headers['Content-Type'] = 'multipart/form-data';
      
      final mimeType = _getMimeType(imageFile.name);
      print("Uploading file: ${imageFile.name}");
      print("Detected MIME: ${mimeType.mimeType}");
      
      // Web: use fromBytes (dart:io File not available)
      // Mobile: use fromPath (more efficient)
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: imageFile.name,
          contentType: mimeType,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: mimeType,
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
      
      // Try to parse error message from response body
      String errorMsg = '${response.statusCode} ${response.reasonPhrase}';
      try {
        final errorJson = jsonDecode(response.body);
        if (errorJson is Map && errorJson['error'] != null) {
          errorMsg = errorJson['error'].toString();
        }
      } catch (_) {
        // body wasn't JSON, use status code message
      }
      throw Exception('Scan failed: $errorMsg');
    } catch (e) {
      debugPrint('[ScanService] Error: $e');
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

  static MediaType _getMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();

    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      default:
        return MediaType('application', 'octet-stream');
    }
  }
}
