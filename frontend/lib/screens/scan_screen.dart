import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
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
    }
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

          return Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
                  ),
                ),
              ),
              Center(
                child: ScannerOverlay(isScanning: provider.state == ScanState.scanning),
              ),
              _buildTopBar(context),
              if (provider.state == ScanState.scanning)
                Positioned(
                  bottom: widget.embeddedInShell ? 220 : 180,
                  left: 40,
                  right: 40,
                  child: _buildScanningIndicator(),
                ),
              if (provider.state == ScanState.idle)
                Positioned(
                  bottom: widget.embeddedInShell ? 220 : 180,
                  left: 40,
                  right: 40,
                  child: Text(
                    'Position the artifact within the frame',
                    textAlign: TextAlign.center,
                    style: KuriftuTheme.bodyText.copyWith(
                      color: KuriftuColors.textSecondary.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
              _buildBottomControls(context, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
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
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: KuriftuColors.glassBorder, width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 18),
                        if (widget.embeddedInShell) ...[
                          const SizedBox(width: 6),
                          Text(
                            'Home',
                            style: TextStyle(fontFamily: 'Inter', 
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Cultural Scanner',
                style: TextStyle(fontFamily: 'PlayfairDisplay', 
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: KuriftuColors.textPrimary,
                ),
              ),
            ),
            const Icon(LucideIcons.sparkles, color: KuriftuColors.gold, size: 18),
            const SizedBox(width: 6),
            Text('AI', style: KuriftuTheme.goldAccent.copyWith(fontSize: 14)),
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
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: KuriftuColors.glassBorder, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(KuriftuColors.gold),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'AI is analyzing the artifact...',
                style: KuriftuTheme.bodyText.copyWith(color: KuriftuColors.textPrimary, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context, ScanProvider provider) {
    final isScanning = provider.state == ScanState.scanning;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 32,
          right: 32,
          bottom: (widget.embeddedInShell ? 88 : 0) + MediaQuery.of(context).padding.bottom + 24,
          top: 24,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCircleAction(
              icon: LucideIcons.image,
              label: 'Gallery',
              onTap: isScanning ? null : () => provider.scanFromGallery(),
            ),
            GestureDetector(
              onTap: isScanning ? null : () => provider.scanDemo(),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isScanning ? KuriftuColors.textMuted : KuriftuColors.gold,
                    width: 3,
                  ),
                  boxShadow: isScanning
                      ? []
                      : [BoxShadow(color: KuriftuColors.gold.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2)],
                ),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isScanning ? KuriftuColors.surfaceLight : KuriftuColors.gold,
                  ),
                  child: isScanning
                      ? const Padding(
                          padding: EdgeInsets.all(22),
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: KuriftuColors.gold),
                        )
                      : const Icon(LucideIcons.scan, color: Colors.black, size: 30),
                ),
              ),
            ),
            _buildCircleAction(
              icon: LucideIcons.camera,
              label: 'Camera',
              onTap: isScanning ? null : () => provider.scanFromCamera(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleAction({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: KuriftuColors.glassBorder, width: 0.5),
            ),
            child: Icon(icon, color: KuriftuColors.textSecondary, size: 22),
          ),
          const SizedBox(height: 8),
          Text(label, style: KuriftuTheme.labelText.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

