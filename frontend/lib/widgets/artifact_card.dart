import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/artifact.dart';
import '../theme/app_theme.dart';

class ArtifactCard extends StatelessWidget {
  final Artifact artifact;
  final VoidCallback? onTap;
  final double height;

  const ArtifactCard({
    super.key,
    required this.artifact,
    this.onTap,
    this.height = 260,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'artifact-${artifact.id}',
        child: Container(
          height: height,
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
                _buildGradientOverlay(),
                _buildContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (artifact.image.startsWith('assets/')) {
      return Image.asset(
        artifact.image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AfrilensColors.surfaceLight,
          child: const Icon(LucideIcons.image, color: AfrilensColors.textMuted, size: 40),
        ),
      );
    }
    return Image.network(
      artifact.image,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AfrilensColors.surfaceLight,
        child: const Icon(LucideIcons.image, color: AfrilensColors.textMuted, size: 40),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.85),
          ],
          stops: const [0.3, 0.6, 1.0],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AfrilensColors.glassBorder, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  artifact.name,
                  style: AfrilensTheme.headlineSerif.copyWith(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      artifact.countryName,
                      style: AfrilensTheme.goldAccent.copyWith(fontSize: 12),
                    ),
                    Text(
                      '\$${artifact.price.toStringAsFixed(0)}',
                      style: AfrilensTheme.headlineSerif.copyWith(
                        fontSize: 18,
                        color: AfrilensColors.gold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
