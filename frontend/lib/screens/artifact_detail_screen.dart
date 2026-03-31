import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/artifact.dart';
import '../theme/app_theme.dart';
import '../widgets/gold_button.dart';
import 'order_screen.dart';

class ArtifactDetailScreen extends StatelessWidget {
  final Artifact artifact;

  const ArtifactDetailScreen({super.key, required this.artifact});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KuriftuColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(child: _buildBody(context)),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 380,
      pinned: true,
      backgroundColor: KuriftuColors.surface,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'artifact-${artifact.id}',
              child: _buildImage(),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    KuriftuColors.background.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ],
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
          color: Colors.grey[300],
          child: const Icon(Icons.image_not_supported),
        ),
      );
    }
    return Image.network(
      artifact.image,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint("Image Load Error [ArtifactDetailScreen]: ${artifact.image} | $error");
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.image_not_supported),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      transform: Matrix4.translationValues(0, -32, 0),
      decoration: const BoxDecoration(
        color: KuriftuColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Text(
            artifact.name,
            style: TextStyle(fontFamily: 'PlayfairDisplay', 
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: KuriftuColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Country chip
          Row(
            children: [
              _buildChip(LucideIcons.mapPin, artifact.countryName),
              if (artifact.isAiGenerated) ...[
                const SizedBox(width: 10),
                _buildChip(LucideIcons.sparkles, 'AI Generated'),
              ],
            ],
          ),
          const SizedBox(height: 32),

          // Story section
          _buildSectionTitle('Cultural History'),
          const SizedBox(height: 16),
          Text(
            artifact.fullStory,
            style: KuriftuTheme.bodyText.copyWith(
              fontSize: 15,
              height: 1.8,
              color: KuriftuColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Materials & Significance cards
          _buildInfoCard(
            icon: LucideIcons.palette,
            title: 'Materials & Craftsmanship',
            content: artifact.materials,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            icon: LucideIcons.heart,
            title: 'Cultural Significance',
            content: artifact.culturalSignificance,
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 20,
          decoration: BoxDecoration(
            color: KuriftuColors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(fontFamily: 'PlayfairDisplay', 
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: KuriftuColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: KuriftuColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KuriftuColors.gold.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: KuriftuColors.gold),
          const SizedBox(width: 6),
          Text(label, style: KuriftuTheme.goldAccent.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: KuriftuColors.glassBorder, width: 0.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: KuriftuColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: KuriftuColors.gold, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: KuriftuTheme.headlineSerif.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      content,
                      style: KuriftuTheme.bodyText.copyWith(
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: KuriftuColors.surface.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PRICE',
                    style: KuriftuTheme.labelText.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${artifact.price.toStringAsFixed(2)}',
                    style: TextStyle(fontFamily: 'PlayfairDisplay', 
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: KuriftuColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: 180,
                child: GoldButton(
                  text: 'PURCHASE',
                  icon: LucideIcons.shoppingBag,
                  height: 50,
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
}

