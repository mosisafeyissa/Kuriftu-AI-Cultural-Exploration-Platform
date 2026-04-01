import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';
import 'villa_guide_screen.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isNavigating = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isNavigating) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && _isValidUUID(code)) {
        setState(() => _isNavigating = true);
        _navigateToGuide(code);
        break;
      }
    }
  }

  bool _isValidUUID(String str) {
    final RegExp uuidRegExp = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegExp.hasMatch(str);
  }

  void _navigateToGuide(String qrCode) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => VillaGuideScreen(qrCode: qrCode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          // Scanner Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: KuriftuColors.gold, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          // Back Button
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Scan Villa QR Code',
                  style: KuriftuTheme.headlineSerif.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  'Point your camera at the QR code\nin your villa to start the journey.',
                  textAlign: TextAlign.center,
                  style: KuriftuTheme.bodyText,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
