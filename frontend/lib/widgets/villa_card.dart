import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/villa.dart';
import '../theme/app_theme.dart';

class VillaCard extends StatelessWidget {
  final Villa villa;
  final VoidCallback? onTap;

  const VillaCard({
    super.key,
    required this.villa,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: AfrilensTheme.softShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImage(),
              _buildOverlay(),
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (villa.image.startsWith('assets/')) {
      return Image.asset(villa.image, fit: BoxFit.cover);
    }
    return Image.network(
      villa.image,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AfrilensColors.surfaceLight,
        child: const Icon(LucideIcons.building, color: AfrilensColors.textMuted, size: 40),
      ),
    );
  }

  Widget _buildOverlay() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AfrilensColors.glassBorder, width: 0.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        villa.name,
                        style: AfrilensTheme.headlineSerif.copyWith(fontSize: 17),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        villa.description,
                        style: AfrilensTheme.bodyText.copyWith(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AfrilensColors.gold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.arrowRight,
                    color: AfrilensColors.gold,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
