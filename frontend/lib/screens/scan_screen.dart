import 'package:flutter/material.dart';
import '../services/scan_service.dart';
import 'result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startScan() async {
    setState(() {
      _isScanning = true;
    });

    final artifact = await ScanService.scanObject();
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(artifact: artifact),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Scan Object', style: TextStyle(color: Colors.white)),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Mock Camera Viewfinder Box
          Center(
            child: Container(
              width: 300,
              height: 400,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFC79A3F), width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: _isScanning
                  ? AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Align(
                          alignment: Alignment(0, -1.0 + (_animationController.value * 2.0)),
                          child: Container(
                            height: 4,
                            width: 280,
                            decoration: BoxDecoration(
                              color: const Color(0xFFC79A3F),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFC79A3F).withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Text(
                        'Align object within frame',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
            ),
          ),
          
          Positioned(
            bottom: 60,
            child: GestureDetector(
              onTap: _isScanning ? null : _startScan,
              child: Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  color: _isScanning ? Colors.grey : const Color(0xFFC79A3F),
                ),
                child: _isScanning
                    ? const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                    : const Icon(Icons.camera_alt, color: Colors.white, size: 36),
              ),
            ),
          ),
          
          if (_isScanning)
            const Positioned(
              bottom: 20,
              child: Text(
                'AI is analyzing the cultural artifact...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            )
        ],
      ),
    );
  }
}
