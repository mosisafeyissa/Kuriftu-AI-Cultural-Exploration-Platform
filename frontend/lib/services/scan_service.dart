import '../models/artifact.dart';
import 'api_service.dart';

class ScanService {
  static Future<Artifact> scanObject() async {
    // Simulate AI processing delay (e.g. 2.5 seconds)
    await Future.delayed(const Duration(milliseconds: 2500));
    
    // For MVP, always 'discover' the Ethiopian coffee table mock
    return ApiService.mockArtifacts.first;
  }
}
