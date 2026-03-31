import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/artifact.dart';
import 'api_service.dart';

class ScanService {
  static const String _scanUrl = 'http://10.0.2.2:8000/api/scan/';
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> captureImage() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (photo == null) return null;
    return File(photo.path);
  }

  static Future<File?> pickFromGallery() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (photo == null) return null;
    return File(photo.path);
  }

  static Future<Artifact> scanWithImage(File imageFile) async {
    if (ApiService.useMockData) {
      await Future.delayed(const Duration(milliseconds: 2500));
      final artifacts = ApiService.mockArtifacts;
      final name = imageFile.path.toLowerCase();
      for (final artifact in artifacts) {
        final keywords = artifact.name.toLowerCase().split(' ');
        for (final kw in keywords) {
          if (kw.length > 3 && name.contains(kw)) return artifact;
        }
      }
      return artifacts[DateTime.now().millisecond % artifacts.length];
    }

    final request = http.MultipartRequest('POST', Uri.parse(_scanUrl));
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 200) {
      return Artifact.fromScanJson(jsonDecode(response.body));
    }
    throw Exception('Scan failed: ${response.body}');
  }

  static Future<Artifact> scanMockDemo() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    return ApiService.mockArtifacts[DateTime.now().second % ApiService.mockArtifacts.length];
  }
}
