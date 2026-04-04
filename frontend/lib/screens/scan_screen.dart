import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../widgets/scanner_overlay.dart';
import '../providers/scan_provider.dart';
import 'result_screen.dart';
import 'main_shell.dart';

class ScanScreen extends StatefulWidget {
  final bool embeddedInShell;
  const ScanScreen({super.key, this.embeddedInShell = false});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScanProvider>().reset();
    });
  }

  void _onScanComplete(ScanProvider provider) {
    if (provider.state == ScanState.complete && provider.result != null) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => ResultScreen(artifact: provider.result!),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, anim, __, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: FadeTransition(opacity: anim, child: child),
            );
          },
        ),
      );
    } else if (provider.state == ScanState.notFound) {
      _showNotFoundSheet(provider);
    } else if (provider.state == ScanState.error && provider.errorMessage != null) {
      final msg = provider.errorMessage!.replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.alertCircle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(msg, style: const TextStyle(fontFamily: 'Inter', color: Colors.white, fontSize: 14))),
            ],
          ),
          backgroundColor: Colors.red.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
      provider.reset();
    }
  }

  void _showNotFoundSheet(ScanProvider provider) {
    final similarity = provider.lastSimilarity ?? 0.0;
    final pct = (similarity * 100).toInt();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.fromLTRB(28, 28, 28, MediaQuery.of(context).padding.bottom + 28),
            decoration: BoxDecoration(
              color: AfrilensColors.surface.withOpacity(0.92),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: AfrilensColors.glassBorder, width: 0.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AfrilensColors.textMuted.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 28),
                // Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AfrilensColors.gold.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.searchX, color: AfrilensColors.gold, size: 40),
                ),
                const SizedBox(height: 24),
                Text(
                  'No Match Found',
                  style: AfrilensTheme.headlineSerif.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  'We couldn\'t find a matching artifact in our collection.',
                  textAlign: TextAlign.center,
                  style: AfrilensTheme.bodyText.copyWith(fontSize: 14, color: AfrilensColors.textSecondary, height: 1.5),
                ),
                if (pct > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AfrilensColors.glassBorder),
                    ),
                    child: Text('Closest match: $pct% similarity',
                      style: AfrilensTheme.labelText.copyWith(fontSize: 12, color: AfrilensColors.textMuted)),
                  ),
                ],
                const SizedBox(height: 28),
                // Tips
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AfrilensColors.gold.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AfrilensColors.gold.withOpacity(0.15)),
                  ),
                  child: Column(
                    children: [
                      _tipRow(LucideIcons.sun, 'Ensure good lighting'),
                      const SizedBox(height: 10),
                      _tipRow(LucideIcons.focus, 'Get closer to the artifact'),
                      const SizedBox(height: 10),
                      _tipRow(LucideIcons.rotateCw, 'Try a different angle'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () { Navigator.pop(context); provider.reset(); provider.scanFromGallery(); },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: AfrilensColors.gold, width: 1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.image, color: AfrilensColors.gold, size: 18),
                              const SizedBox(width: 8),
                              Text('GALLERY', style: AfrilensTheme.goldAccent.copyWith(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () { Navigator.pop(context); provider.reset(); provider.scanFromCamera(); },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFB8860B)]),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.camera, color: Colors.black, size: 18),
                              SizedBox(width: 8),
                              Text('RETRY', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black, letterSpacing: 1)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      if (provider.state == ScanState.notFound) {
        provider.reset();
      }
    });
  }

  Widget _tipRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AfrilensColors.gold.withOpacity(0.7)),
        const SizedBox(width: 12),
        Text(text, style: AfrilensTheme.bodyText.copyWith(fontSize: 13, color: AfrilensColors.textSecondary)),
      ],
    );
  }

  /// Show the captured/uploaded image as background during scanning
  Widget _buildCapturedImageBg(ScanProvider provider) {
    final img = provider.capturedImage;
    if (img == null) return const SizedBox.shrink();
    if (kIsWeb) {
      return Image.network(img.path, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
        errorBuilder: (_, __, ___) => const SizedBox.shrink());
    }
    return Image.file(File(img.path), fit: BoxFit.cover, width: double.infinity, height: double.infinity,
      errorBuilder: (_, __, ___) => const SizedBox.shrink());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<ScanProvider>(
        builder: (context, provider, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _onScanComplete(provider);
          });

          final isScanning = provider.state == ScanState.scanning;
          final hasImage = isScanning && provider.capturedImage != null;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Background: uploaded image during scanning, dark gradient otherwise
              if (hasImage) ...[
                _buildCapturedImageBg(provider),
                Container(color: Colors.black.withOpacity(0.5)),
              ] else
                Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center, radius: 1.2,
                      colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
                    ),
                  ),
                ),

              // Scanner overlay (hide when showing image)
              if (!hasImage)
                Center(
                  child: ScannerOverlay(isScanning: isScanning),
                ),

              // Top bar
              _buildTopBar(context),

              // Status message
              if (isScanning)
                Positioned(
                  bottom: widget.embeddedInShell ? 220 : 180,
                  left: 40, right: 40,
                  child: _buildScanningIndicator(),
                ),
              if (provider.state == ScanState.idle)
                Positioned(
                  bottom: widget.embeddedInShell ? 220 : 180,
                  left: 40, right: 40,
                  child: Text(
                    'Position the artifact within the frame',
                    textAlign: TextAlign.center,
                    style: AfrilensTheme.bodyText.copyWith(color: AfrilensColors.textSecondary.withOpacity(0.7), fontSize: 14),
                  ),
                ),

              // Bottom controls
              _buildBottomControls(context, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16, right: 16, bottom: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: widget.embeddedInShell
                  ? () => context.findAncestorStateOfType<MainShellState>()?.switchToTab(0)
                  : () => Navigator.pop(context),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AfrilensColors.glassBorder, width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 18),
                        if (widget.embeddedInShell) ...[
                          const SizedBox(width: 6),
                          const Text('Home', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Cultural Scanner',
                style: TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 20, fontWeight: FontWeight.w600, color: AfrilensColors.textPrimary),
              ),
            ),
            const Icon(LucideIcons.sparkles, color: AfrilensColors.gold, size: 18),
            const SizedBox(width: 6),
            Text('AI', style: AfrilensTheme.goldAccent.copyWith(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningIndicator() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AfrilensColors.glassBorder, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AfrilensColors.gold)),
              ),
              const SizedBox(width: 14),
              Text('AI is analyzing the artifact...', style: AfrilensTheme.bodyText.copyWith(color: AfrilensColors.textPrimary, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context, ScanProvider provider) {
    final isScanning = provider.state == ScanState.scanning;
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 32, right: 32,
          bottom: (widget.embeddedInShell ? 88 : 0) + MediaQuery.of(context).padding.bottom + 24,
          top: 24,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter, end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.8), Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCircleAction(
              icon: LucideIcons.image, label: 'Gallery',
              onTap: isScanning ? null : () => provider.scanFromGallery(),
            ),
            GestureDetector(
              onTap: isScanning ? null : () => provider.scanDemo(),
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: isScanning ? AfrilensColors.textMuted : AfrilensColors.gold, width: 3),
                  boxShadow: isScanning ? [] : [BoxShadow(color: AfrilensColors.gold.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
                ),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: isScanning ? AfrilensColors.surfaceLight : AfrilensColors.gold),
                  child: isScanning
                      ? const Padding(padding: EdgeInsets.all(22), child: CircularProgressIndicator(strokeWidth: 2.5, color: AfrilensColors.gold))
                      : const Icon(LucideIcons.scan, color: Colors.black, size: 30),
                ),
              ),
            ),
            _buildCircleAction(
              icon: LucideIcons.camera, label: 'Camera',
              onTap: isScanning ? null : () => provider.scanFromCamera(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleAction({required IconData icon, required String label, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: AfrilensColors.glassBorder, width: 0.5),
            ),
            child: Icon(icon, color: AfrilensColors.textSecondary, size: 22),
          ),
          const SizedBox(height: 8),
          Text(label, style: AfrilensTheme.labelText.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}
