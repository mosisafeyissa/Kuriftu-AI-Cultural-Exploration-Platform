// Mobile (IO) implementation — dart:io IS available here.
import 'dart:io' show Platform;

String getBaseUrl() {
  if (Platform.isAndroid) return 'http://10.0.2.2:8000/api';
  if (Platform.isIOS) return 'http://localhost:8000/api';
  // Desktop fallback
  return 'http://127.0.0.1:8000/api';
}
