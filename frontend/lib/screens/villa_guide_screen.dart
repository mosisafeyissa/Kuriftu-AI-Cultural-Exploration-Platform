import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/villa_guide.dart';
import '../models/villa_section.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/artifact_card.dart';

class VillaGuideScreen extends StatefulWidget {
  final String qrCode;

  const VillaGuideScreen({super.key, required this.qrCode});

  @override
  State<VillaGuideScreen> createState() => _VillaGuideScreenState();
}

class _VillaGuideScreenState extends State<VillaGuideScreen> {
  late Future<VillaGuide> _guideFuture;
  String _currentLang = 'en';
  bool _isTranslating = false;

  @override
  void initState() {
    super.initState();
    _guideFuture = ApiService.getVillaGuide(widget.qrCode);
  }

  void _changeLanguage(String lang) async {
    if (lang == _currentLang) return;
    setState(() {
      _isTranslating = true;
      _currentLang = lang;
    });
    try {
      final translated = await ApiService.translateGuide(widget.qrCode, lang);
      setState(() {
        _guideFuture = Future.value(translated);
        _isTranslating = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Translation error: $e')),
        );
      }
      setState(() => _isTranslating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<VillaGuide>(
        future: _guideFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _isTranslating) {
            return const Center(child: CircularProgressIndicator(color: AfrilensColors.gold));
          }
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }
          final guide = snapshot.data!;
          return _buildGuideContent(guide);
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertTriangle, color: Colors.orange, size: 64),
            const SizedBox(height: 16),
            Text('Guided Tour Error', style: AfrilensTheme.headlineSerif.copyWith(fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AfrilensTheme.bodyText,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: AfrilensColors.gold),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideContent(VillaGuide guide) {
    return CustomScrollView(
      slivers: [
        // App Bar with Background Image
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(guide.name, style: AfrilensTheme.headlineSerif.copyWith(fontSize: 18)),
            background: Image.network(
              guide.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[900]),
            ),
          ),
          actions: [
            _buildLanguageSelector(),
          ],
        ),

        // Welcome Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AfrilensColors.gold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AfrilensColors.gold.withOpacity(0.3)),
                      ),
                      child: Text(
                        guide.countryName.toUpperCase(),
                        style: AfrilensTheme.goldAccent.copyWith(fontSize: 10, letterSpacing: 2),
                      ),
                    ),
                    const Spacer(),
                    const Icon(LucideIcons.mapPin, size: 14, color: AfrilensColors.gold),
                    const SizedBox(width: 4),
                    Text(guide.location, style: AfrilensTheme.labelText),
                  ],
                ),
                const SizedBox(height: 24),
                Text('A Cultural Welcome', style: AfrilensTheme.headlineSerif.copyWith(fontSize: 24)),
                const SizedBox(height: 16),
                Text(
                  guide.welcomeStory,
                  style: AfrilensTheme.bodyText.copyWith(fontSize: 16, height: 1.8),
                ),
                const SizedBox(height: 40),
                Text('Cultural Highlights', style: AfrilensTheme.headlineSerif.copyWith(fontSize: 20)),
                const SizedBox(height: 16),
                ...guide.culturalHighlights.map((h) => _buildHighlightItem(h)),
                const SizedBox(height: 48),
                Text('The Guided Journey', style: AfrilensTheme.headlineSerif.copyWith(fontSize: 24)),
                const SizedBox(height: 12),
                Text(
                  'Explore each corner of the ${guide.name} and uncover the stories within.',
                  style: AfrilensTheme.bodyText,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Sections List
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final section = guide.sections[index];
                return _buildSectionCard(section, index + 1);
              },
              childCount: guide.sections.length,
            ),
          ),
        ),

        // Bottom Padding
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildHighlightItem(String highlight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.sparkles, color: AfrilensColors.gold, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              highlight,
              style: AfrilensTheme.bodyText.copyWith(color: AfrilensColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(VillaSection section, int number) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: AfrilensTheme.glassDecoration.copyWith(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.imageUrl != null)
            Image.network(
              section.imageUrl!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'STEP $number',
                      style: AfrilensTheme.goldAccent.copyWith(fontSize: 12),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.chevronRight, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(section.name, style: AfrilensTheme.headlineSerif.copyWith(fontSize: 20)),
                const SizedBox(height: 12),
                Text(
                  section.description,
                  style: AfrilensTheme.bodyText.copyWith(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 16),
                Text(
                  section.narrative,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AfrilensTheme.bodyText,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _openSectionDetail(section),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AfrilensColors.gold.withOpacity(0.2),
                      foregroundColor: AfrilensColors.gold,
                      elevation: 0,
                      side: const BorderSide(color: AfrilensColors.gold, width: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Explore Room'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openSectionDetail(VillaSection section) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SectionDetailScreen(section: section),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    final Map<String, String> langs = {
      'en': '🇺🇸 EN',
      'am': '🇪🇹 AM',
      'fr': '🇫🇷 FR',
      'ar': '🇸🇦 AR',
      'sw': '🇰🇪 SW',
    };

    return PopupMenuButton<String>(
      icon: const Icon(LucideIcons.languages, color: AfrilensColors.gold),
      onSelected: _changeLanguage,
      itemBuilder: (context) => langs.entries.map((e) {
        return PopupMenuItem(
          value: e.key,
          child: Text(e.value),
        );
      }).toList(),
    );
  }
}

// ── Section Detail Screen ───────────────────────────────────────────────────

class SectionDetailScreen extends StatelessWidget {
  final VillaSection section;

  const SectionDetailScreen({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(section.name, style: AfrilensTheme.headlineSerif.copyWith(fontSize: 16)),
              background: section.imageUrl != null 
                ? Image.network(section.imageUrl!, fit: BoxFit.cover)
                : Container(color: Colors.grey[900]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.narrative,
                    style: AfrilensTheme.bodyText.copyWith(fontSize: 18, height: 1.8),
                  ),
                  const SizedBox(height: 48),
                  Text('Artifacts in this Area', style: AfrilensTheme.headlineSerif.copyWith(fontSize: 20)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final artifact = section.artifacts[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: ArtifactCard(artifact: artifact),
                  );
                },
                childCount: section.artifacts.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}
