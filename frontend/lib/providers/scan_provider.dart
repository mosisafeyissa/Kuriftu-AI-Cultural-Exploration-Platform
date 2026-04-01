import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/artifact.dart';
import '../services/scan_service.dart';

enum ScanState { idle, capturing, scanning, complete, notFound, error }

class ScanProvider extends ChangeNotifier {
  ScanState _state = ScanState.idle;
  Artifact? _result;
  XFile? _capturedImage;
  String? _errorMessage;
  double? _lastSimilarity;

  ScanState get state => _state;
  Artifact? get result => _result;
  XFile? get capturedImage => _capturedImage;
  String? get errorMessage => _errorMessage;
  double? get lastSimilarity => _lastSimilarity;

  void reset() {
    _state = ScanState.idle;
    _result = null;
    _capturedImage = null;
    _errorMessage = null;
    _lastSimilarity = null;
    notifyListeners();
  }

  Future<void> scanFromCamera() async {
    _state = ScanState.capturing;
    notifyListeners();

    try {
      final file = await ScanService.captureImage();
      if (file == null) {
        _state = ScanState.idle;
        notifyListeners();
        return;
      }
      _capturedImage = file;
      _state = ScanState.scanning;
      notifyListeners();

      _result = await ScanService.scanWithImage(file);
      _state = ScanState.complete;
    } on ScanNotFoundException catch (e) {
      _errorMessage = e.message;
      _lastSimilarity = e.similarity;
      _state = ScanState.notFound;
    } catch (e) {
      _errorMessage = e.toString();
      _state = ScanState.error;
    }
    notifyListeners();
  }

  Future<void> scanFromGallery() async {
    _state = ScanState.capturing;
    notifyListeners();

    try {
      final file = await ScanService.pickFromGallery();
      if (file == null) {
        _state = ScanState.idle;
        notifyListeners();
        return;
      }
      _capturedImage = file;
      _state = ScanState.scanning;
      notifyListeners();

      _result = await ScanService.scanWithImage(file);
      _state = ScanState.complete;
    } on ScanNotFoundException catch (e) {
      _errorMessage = e.message;
      _lastSimilarity = e.similarity;
      _state = ScanState.notFound;
    } catch (e) {
      _errorMessage = e.toString();
      _state = ScanState.error;
    }
    notifyListeners();
  }

  Future<void> scanDemo() async {
    _state = ScanState.scanning;
    notifyListeners();

    try {
      _result = await ScanService.scanMockDemo();
      _state = ScanState.complete;
    } catch (e) {
      _errorMessage = e.toString();
      _state = ScanState.error;
    }
    notifyListeners();
  }
}
