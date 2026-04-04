import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/artifact.dart';
import '../theme/app_theme.dart';
import '../widgets/gold_button.dart';
import 'artifact_detail_screen.dart';
import 'order_screen.dart';

class ResultScreen extends StatefulWidget {
  final Artifact artifact;

  const ResultScreen({super.key, required this.artifact});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnim = CurvedAnimation(parent: _slideController, curve: Curves.easeOut);
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final artifact = widget.artifact;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AfrilensColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background artifact image
          Hero(
            tag: 'artifact-${artifact.id}',
            child: _buildArtifactImage(artifact),
          ),

          // Dark gradient from bottom
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.95),
                ],
                stops: const [0.0, 0.4, 0.75],
              ),
            ),
          ),

          // Top bar
          _buildTopBar(context),

          // Confidence badge
          if (artifact.confidence != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              right: 24,
              child: _buildConfidenceBadge(artifact.confidence!),
            ),

          // Slide-up glass result card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: _buildResultCard(context, artifact, bottomPad),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtifactImage(Artifact artifact) {
    if (artifact.image.startsWith('assets/')) {
      return Image.asset(
        artifact.image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AfrilensColors.surface,
          child: const Center(
            child: Icon(LucideIcons.image, size: 60, color: AfrilensColors.textMuted),
          ),
        ),
      );
    }
    return Image.network(
      artifact.image,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AfrilensColors.surface,
        child: const Center(
          child: Icon(LucideIcons.image, size: 60, color: AfrilensColors.textMuted),
        ),
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
            colors: [
              Colors.black.withOpacity(0.6),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Text(
              'Artifact Discovered',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AfrilensColors.textPrimary,
              ),
            ),
            const Spacer(),
            const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge(double confidence) {
    final pct = (confidence * 100).toInt();
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AfrilensColors.glassBorder, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.sparkles,
                size: 14,
                color: pct >= 80 ? AfrilensColors.gold : AfrilensColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '$pct% match',
                style: AfrilensTheme.labelText.copyWith(
                  color: AfrilensColors.textPrimary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, Artifact artifact, double bottomPad) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 28, 24, bottomPad + 24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(color: AfrilensColors.glassBorder, width: 0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Artifact name
              Text(
                artifact.name,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AfrilensColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Country + flag chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AfrilensColors.gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.mapPin, size: 14, color: AfrilensColors.gold),
                    const SizedBox(width: 6),
                    Text(
                      artifact.countryName,
                      style: AfrilensTheme.goldAccent.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Info rows
              _buildInfoRow(LucideIcons.palette, 'Materials', artifact.materials),
              const SizedBox(height: 12),
              _buildInfoRow(LucideIcons.heart, 'Significance', artifact.culturalSignificance),
              const SizedBox(height: 24),

              // Divider
              Container(
                height: 0.5,
                color: Colors.white.withOpacity(0.1),
              ),
              const SizedBox(height: 20),

              // Price + actions
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Purchase Value',
                        style: AfrilensTheme.labelText.copyWith(fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${artifact.price.toStringAsFixed(2)}',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AfrilensColors.gold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GoldButton(
                    text: 'FULL STORY',
                    isOutlined: true,
                    height: 46,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArtifactDetailScreen(artifact: artifact),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Buy button
              SizedBox(
                width: double.infinity,
                child: GoldButton(
                  text: 'BUY NOW',
                  icon: LucideIcons.shoppingBag,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderScreen(artifact: artifact),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AfrilensColors.gold.withOpacity(0.7)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: AfrilensTheme.labelText.copyWith(fontSize: 10, letterSpacing: 1.5),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AfrilensTheme.bodyText.copyWith(
                  color: AfrilensColors.textPrimary.withOpacity(0.85),
                  fontSize: 13,
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
