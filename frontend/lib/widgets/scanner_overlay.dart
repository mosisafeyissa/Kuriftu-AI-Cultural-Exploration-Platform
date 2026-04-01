import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ScannerOverlay extends StatefulWidget {
  final bool isScanning;

  const ScannerOverlay({super.key, this.isScanning = false});

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final frameW = constraints.maxWidth * 0.75;
        final frameH = frameW * 1.25;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Corner brackets
            SizedBox(
              width: frameW,
              height: frameH,
              child: CustomPaint(
                painter: _CornerPainter(
                  color: widget.isScanning
                      ? KuriftuColors.gold
                      : KuriftuColors.gold.withValues(alpha: 0.5),
                  cornerLength: 36,
                  strokeWidth: 3,
                  radius: 20,
                ),
              ),
            ),

            // Scanning line — always animated
              SizedBox(
                width: frameW,
                height: frameH,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Align(
                      alignment: Alignment(
                        0,
                        -1.0 + (_controller.value * 2.0),
                      ),
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              KuriftuColors.gold.withValues(alpha: 0.0),
                              widget.isScanning
                                  ? KuriftuColors.gold
                                  : KuriftuColors.gold.withValues(alpha: 0.5),
                              KuriftuColors.gold.withValues(alpha: 0.0),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: KuriftuColors.gold.withValues(alpha: widget.isScanning ? 0.6 : 0.3),
                              blurRadius: widget.isScanning ? 16 : 8,
                              spreadRadius: widget.isScanning ? 4 : 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double cornerLength;
  final double strokeWidth;
  final double radius;

  _CornerPainter({
    required this.color,
    required this.cornerLength,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final cl = cornerLength;
    final r = radius;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, cl)
        ..lineTo(0, r)
        ..quadraticBezierTo(0, 0, r, 0)
        ..lineTo(cl, 0),
      paint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(w - cl, 0)
        ..lineTo(w - r, 0)
        ..quadraticBezierTo(w, 0, w, r)
        ..lineTo(w, cl),
      paint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(w, h - cl)
        ..lineTo(w, h - r)
        ..quadraticBezierTo(w, h, w - r, h)
        ..lineTo(w - cl, h),
      paint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(cl, h)
        ..lineTo(r, h)
        ..quadraticBezierTo(0, h, 0, h - r)
        ..lineTo(0, h - cl),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerPainter old) =>
      old.color != color || old.cornerLength != cornerLength;
}
