
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/villa.dart';
import '../models/artifact.dart';
import '../widgets/artifact_card.dart';
import 'artifact_detail_screen.dart';

class VillasScreen extends StatefulWidget {
  const VillasScreen({super.key});

  @override
  State<VillasScreen> createState() => _VillasScreenState();
}

class _VillasScreenState extends State<VillasScreen> {
  List<Villa> _villas = [];
  Map<String, List<Artifact>> _villaArtifacts = {};
  bool _isLoading = true;
  String? _selectedVillaId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final villas = await ApiService.getVillas();
      final artifacts = await ApiService.getArtifacts();

      final grouped = <String, List<Artifact>>{};
      for (final a in artifacts) {
        grouped.putIfAbsent(a.villaId, () => []).add(a);
      }

      if (mounted) {
        setState(() {
          _villas = villas;
          _villaArtifacts = grouped;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[VillasScreen] Load error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KuriftuColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            if (_selectedVillaId != null) {
              setState(() => _selectedVillaId = null);
            } else {
              Navigator.pop(context);
            }
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
          ),
        ),
        title: Text(
          _selectedVillaId == null ? 'African Villas' : _villas.firstWhere((v) => v.id == _selectedVillaId).name,
          style: TextStyle(fontFamily: 'PlayfairDisplay', 
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: KuriftuColors.textPrimary,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: KuriftuColors.gold, strokeWidth: 2),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.wifiOff, color: KuriftuColors.textMuted, size: 36),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: KuriftuTheme.bodyText.copyWith(color: KuriftuColors.textMuted, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _loadData,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: KuriftuColors.gold, width: 1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('Retry', style: KuriftuTheme.goldAccent.copyWith(fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _selectedVillaId == null
                  ? _buildVillaList()
                  : _buildVillaArtifacts(),
    );
  }

  Widget _buildVillaList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      itemCount: _villas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final villa = _villas[index];
        return _ReferenceVillaCard(
          villa: villa,
          artifactCount: _villaArtifacts[villa.id]?.length ?? 0,
          onTap: () => setState(() => _selectedVillaId = villa.id),
        );
      },
    );
  }

  Widget _buildVillaArtifacts() {
    final villa = _villas.firstWhere((v) => v.id == _selectedVillaId);
    final artifacts = _villaArtifacts[villa.id] ?? [];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(villa.description, style: KuriftuTheme.bodyText.copyWith(fontSize: 15)),
                const SizedBox(height: 8),
                Text('${artifacts.length} artifacts', style: KuriftuTheme.goldAccent.copyWith(fontSize: 13)),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.72,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final artifact = artifacts[index];
                return ArtifactCard(
                  artifact: artifact,
                  height: double.infinity,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ArtifactDetailScreen(artifact: artifact)),
                  ),
                );
              },
              childCount: artifacts.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

class _ReferenceVillaCard extends StatelessWidget {
  final Villa villa;
  final int artifactCount;
  final VoidCallback onTap;

  const _ReferenceVillaCard({
    required this.villa,
    required this.artifactCount,
    required this.onTap,
  });

  Widget _buildVillaImage(String imagePath) {
    final isNetwork = imagePath.startsWith('http://') || imagePath.startsWith('https://');
    final errorWidget = Container(
      color: KuriftuColors.surfaceLight,
      child: const Center(
        child: Icon(LucideIcons.image, color: KuriftuColors.textMuted, size: 40),
      ),
    );

    if (isNetwork) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => errorWidget,
      );
    }
    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => errorWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: _buildVillaImage(villa.image),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      villa.countryName.toUpperCase(),
                      style: TextStyle(fontFamily: 'Inter', 
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$artifactCount artifacts',
                      style: TextStyle(fontFamily: 'Inter', 
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: KuriftuColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            villa.name,
            style: TextStyle(fontFamily: 'PlayfairDisplay', 
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: KuriftuColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            villa.description,
            style: KuriftuTheme.bodyText.copyWith(fontSize: 13, height: 1.5),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

